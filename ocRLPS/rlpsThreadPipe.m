//
//  rlpsThreadPipe.m
//  线程间数据管道
//
//  Created by Real on 2017/3/9.
//  Copyright © 2017年 Real. All rights reserved.
//

#import "rlpsThreadPipe.h"
#import "rlpsDWList.h"

#pragma mark 0 static/global variable

static dispatch_queue_t     rlpsPipeOptQueue;   // 共享的管道的串行操作队列（serial queue）
static dispatch_once_t      rlpsPipeOptQueueCreateOnce;

@implementation rlpsThreadPipe
#pragma mark 1 private class variable
{
    rlpsDWList* pipeList;  // 存放push到管道中的数据，Head为最老的数据，Tail为最新的数据
    rlpsDWList* blockList; // 记录正在阻塞等待数据的pop操作信息，Head为最老的请求，Tail为最新的请求
    
    id<rlpsPipeProcessor> pipeProcessor; // 自动处理pipe数据的处理器
    
    NSString*   objID;     // 每个Pipe的唯一标识
}

#pragma mark 2 construct & destruct & other rewrite
-(nullable instancetype)init
{
    if (self = [super init])
    {
        dispatch_once(&rlpsPipeOptQueueCreateOnce, ^
        {
            rlpsPipeOptQueue  = dispatch_queue_create("optQueue.rlpsThreadPipe", NULL);
        });
    }
    
    pipeList  = [rlpsDWList new];
    blockList = [rlpsDWList new];
    
    pipeProcessor = nil;
    
    // 生成当前管道的唯一标识 (时间戳_Hash值)
    NSTimeInterval tLable = [NSDate timeIntervalSinceReferenceDate];
    objID = [[NSString alloc] initWithFormat:@"%f_%lu", tLable, (unsigned long)[self hash]];
    
    return self;
}

-(void)dealloc
{
    [self clearPipe];
    pipeList  = nil;
    blockList = nil;
}


#pragma mark 3 class function
/* 发起串行请求，向管道中压入新数据 */
-(BOOL)push: (nonnull id)data error:(NSError  * _Nullable * _Nullable)err;
{
    if (nil==data)
    {
        if (err) *err = [rlpsThreadPipe _error:101 :@"a nil data is pushed to pipe"];
        return NO;
    }
    
    __block BOOL pushResult = YES;
    dispatch_sync(rlpsPipeOptQueue, ^
    {
        // 检查是否有blockPop正在等待，有的话直接把数据丢给最早等待的blockPop
        if (nil== pipeProcessor && blockList.length>0)
        {
            NSMutableDictionary* popInfo = [blockList rmvFromHead];
            [popInfo setObject: data forKey: @"data"];
            dispatch_semaphore_signal([popInfo objectForKey: @"sig"]);
            
            if (err) *err = nil;
            return;
        }

        // 没有blockPop正在等待，就将数据正常放入管道
        if (nil == [pipeList add2Tail: data])
        {
            pushResult = NO;
            
            if (err) *err = [rlpsThreadPipe _error:102 :@"push data to pipe faild"];
            return;
        }
        
        // 检查是否达到了触发porcessor的条件
        // 达到了就取出 batchSize 长度的数据丢给processor处理
        if (pipeProcessor && pipeList.length>=pipeProcessor.batchSize)
        {
            [self _callProcessorOnce];
            return;
        }
    });
    
    return pushResult;
}

/* 发起串行请求，从管道中弹出最早的数据，非阻塞 */
-(nullable id)pop: (NSError  * _Nullable * _Nullable)err
{
    __block id data = nil;
    
    dispatch_sync(rlpsPipeOptQueue, ^
    {
        // 如果存在独占模式的processor，直接返回nil并提供NSError
        if (pipeProcessor && pipeProcessor.exclusive)
        {
            if (err) *err = [rlpsThreadPipe _error:106 :@"pipe has processor within exclusive mode"];
            return;
        }
        
        if (pipeList.length>0 && nil==pipeProcessor)
        {
            data = [pipeList rmvFromHead];
        }
    });
    
    return data;
}

/* 发起串行请求，从管道中弹出最早的数据，阻塞 */
-(nullable id)blockPop: (NSError  * _Nullable * _Nullable)err
{
    __block id data = nil;
    __block BOOL notExclusiveRtn = YES;
    NSMutableDictionary* popInfo = [[NSMutableDictionary alloc] initWithCapacity: 2];
    
    dispatch_sync(rlpsPipeOptQueue, ^
    {
        // 如果存在独占模式的processor，直接返回nil并提供NSError
        if (pipeProcessor && pipeProcessor.exclusive)
        {
            if (err) *err = [rlpsThreadPipe _error:104 :@"pipe has processor within exclusive mode"];
            notExclusiveRtn = NO;
            return;
        }
        
        if (pipeList.length>0 && nil==pipeProcessor)
        {
            // 管道有数据且没有装配processor，直接取出
            data = [pipeList rmvFromHead];
        }
        else
        {
            // 管道没数据，或装配了processor（非独占）
            // 为其创建一个dispatch_semaphore_t放到popInfo中，然后将popInfo排队到阻塞对列末尾
            dispatch_semaphore_t popSig = dispatch_semaphore_create(0);
            [popInfo setObject: popSig forKey:@"sig"];
            [blockList add2Tail: popInfo];
        }
    });
    
    if (nil==data && notExclusiveRtn)
    {
        // 没取到数据，一直阻塞在这里，直到 :
        //     - 有数据
        //     - 管道被清空
        //     - 一个“exclusive processor”被装配
        dispatch_semaphore_wait([popInfo objectForKey: @"sig"], DISPATCH_TIME_FOREVER);
        if ([popInfo objectForKey:@"processor-clean"])
        {
            if (err) *err = [rlpsThreadPipe _error:107 :@"all blockPop are canceled by exclusive processor"];
        }
        else if ([popInfo objectForKey:@"pipe-clean"])
        {
            if (err) *err = [rlpsThreadPipe _error:108 :@"all blockPop are canceled by function 'eraseALL'"];
        }
        else
        {
            data = [popInfo objectForKey: @"data"];
        }
    }
    
    return data;
}

/* 挂载一个遵从rlpsPipeProcessor协议的processor到pipe，如果之前已经挂载了processor，则processor将被替换 */
-(BOOL)mntProcessor: (nullable id<rlpsPipeProcessor>)processor
              error: (NSError  * _Nullable * _Nullable)err
{
    if(processor && ![processor conformsToProtocol: @protocol(rlpsPipeProcessor)])
    {
        if (err) *err = [rlpsThreadPipe _error:103 :@"mount a processor uncomform rlpsPipeProcessor protocol"];
        return NO;
    }
    if (processor && nil==processor.processQueue)
    {
        if (err) *err = [rlpsThreadPipe _error:104 :@"mount a processor with a nil dispatch queue"];
        return NO;
    }
    if (processor && 0==processor.batchSize)
    {
        if (err) *err = [rlpsThreadPipe _error:105 :@"mount a processor with 0 batchSize"];
        return NO;
    }

    
    // 挂载processor
    // 和push、pop一样在pipeQueue中排队，以保证线程安全
    if (err) *err = nil;
    dispatch_sync(rlpsPipeOptQueue, ^
    {
        pipeProcessor = processor;
        if (nil==pipeProcessor) return;
        
        // 释放所有阻塞中的blockPop
        if (pipeProcessor.exclusive)
        {
            while (blockList.length>0)
            {
                NSMutableDictionary* popInfo = [blockList rmvFromHead];
                [popInfo setObject: [NSNull null] forKey: @"processor-clean"];
                dispatch_semaphore_signal([popInfo objectForKey: @"sig"]);
            }
        }
        
        // 处理挂载processor时pipe中已有的数据
        // 如果管道里的数据数据很多，有可能需要很久才能处理完 ……
        // 在循环过程中，如果修改了“clearExist”标志，可能出现数据只被处理了一部分的情况，但这正是我想要的
        while ( !processor.clearExist && pipeList.length>=processor.batchSize )
        {
            [self _callProcessorOnce];
        }
        if (processor.clearExist && pipeList.length>0)
        {
            //[pipeList eraseAll];
            pipeList = [rlpsDWList new];
        }
    });
    
    return YES;
}

/* 清空管道 */
-(void)clearPipe
{
    dispatch_sync(rlpsPipeOptQueue, ^
    {
        [pipeList eraseAll];
        
        // 释放所有阻塞的blockPop
        while (blockList.length>0)
        {
            NSMutableDictionary* popInfo = [blockList rmvFromHead];
            [popInfo setObject: [NSNull null] forKey: @"pipe-clean"];
            dispatch_semaphore_signal([popInfo objectForKey: @"sig"]);
        }
    });
    
    return;
}

#pragma mark 4 tool function
/* 生成一个NSError */
+(NSError*)_error: (NSInteger)code :(NSString*)format, ...
{
    va_list args;
    va_start(args, format);
    NSString* domain = @"errdef.rlpsThreadPipe";
    NSString* desc = [[NSString alloc] initWithFormat:format arguments:args];
    NSDictionary *userinfo = @{NSLocalizedDescriptionKey : desc};
    va_end(args);
    
    return [NSError errorWithDomain:domain code:code userInfo:userinfo];
}

/* 发起一次回调 */
-(void)_callProcessorOnce
{
    id items = nil;
    if (1==pipeProcessor.batchSize)
    {
        items = [pipeList rmvFromHead];
    }
    else
    {
        if (pipeProcessor.batchSize==pipeList.length)
        {
            items = pipeList;
            pipeList = [rlpsDWList new];
        }
        else
        {
            items = [pipeList subListFromHead: pipeProcessor.batchSize];
        }
    }
    
    dispatch_async(pipeProcessor.processQueue, ^
    {
        [pipeProcessor process: items];
    });
    
    return;
}


@end
