//
//  rlpsThreadPipe.h
//  线程间数据管道
//
//  Created by Real on 2017/3/9.
//  Copyright © 2017年 Real. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
 * ---------------------------------------------------------------
 * rlpsThreadPipe管道数据处理回调协议
 * 如果pipe挂载了遵从协议的processor，则processor拥有最高的获取数据优先级
 * 在processor被移除之前，所有的数据都交给此processor处理
 * 直到此porcessor被替换或移除
 * ---------------------------------------------------------------
 */
@class rlpsDWList;
@protocol rlpsPipeProcessor <NSObject>

@required

/* 处理管道数据的dispatch queue */
@property (readonly, atomic) dispatch_queue_t _Nullable processQueue;

/* 一次性处理管道数据的数量，只有管道中数据达到此长度process方法才会被调用 */
@property (readonly, atomic) NSUInteger batchSize;

/* 
 * 是否是独占pipe的processor
 *     如果为YES，则所有pop、blockPop立刻失败
 *     如果为NO，则所有pop立刻返回nil/所有blockPop阻塞，直到processor被移除且管道中填充了新的数据
 */
@property (readonly, atomic) BOOL exclusive;

/*
 * 挂载processor时是否清楚管道中已有的数据
 *     如果为YES，则挂载成功后会清除管道中所有的数据
 *     如果为NO，则挂载成功后会立即处理管道中所有的数据，直到处理完毕
 */
@property (readonly, atomic) BOOL clearExist;

/* 处理管道数据的方法 */
-(void)process: (nonnull rlpsDWList*)objs;

@end


/*
 * ---------------------------------------------------------------
 * 线程间数据(NSObject)管道，先进先出，线程安全，基于ARC／GCD
 * 数据存储基于rlpsDWList，不同管道实例拥有各自的List
 * 管道自带一个“serial dispatch queue”，以实现操作排队，保证数据的线程安全
 * 为了节约系统资源，不同管道实例共享一个“serial dispatch queue”
 * ---------------------------------------------------------------
 */
@interface rlpsThreadPipe : NSObject

/*
 发起串行请求，向管道中压入新数据
 参数：
     (nonnull id)data , 需要放入管道的数据 , 必需是一个NSObject
     (NSError  * _Nullable * _Nullable)err , push失败时为失败描述 , 成功时 *err==nil
 返回值：
     成功 - YES
     失败 - NO
 */
-(BOOL)push: (nonnull id)data error:(NSError  * _Nullable * _Nullable)err;

/*
 发起串行请求，从管道中弹出最早的数据，非阻塞
 参数：
     (NSError  * _Nullable * _Nullable)err , pop失败时为失败描述 , 成功时 *err==nil
 返回值：
     请求被调度时管道中最早的数据
     请求被调度时如果管道中没有数据，返回nil
     pop失败时返回nil
 */
-(nullable id)pop: (NSError  * _Nullable * _Nullable)err;

/*
 发起串行请求，从管道中弹出最早的数据，阻塞
 参数：
     (NSError  * _Nullable * _Nullable)err , pop失败时为失败描述 , 成功时 *err==nil
 返回值：
     请求被调度时管道中最早的数据
     请求被调度时如果管道中没有数据，则一直等待到有数据出现
     当管道被清空时，所有阻塞的blockPop都立即结束，并返回nil
     pop失败时返回nil
 */
-(nullable id)blockPop: (NSError  * _Nullable * _Nullable)err;

/*
 * 挂载一个遵从rlpsPipeProcessor协议的processor到pipe，如果之前已经挂载了processor，则processor将被替换
 * 参数：
 *     (nullable id<threadPipeProcessor>)porcessor , 要挂载的processor
 *     (NSError  * _Nullable * _Nullable)err , 挂载失败时为失败描述 , 成功时为 *err==nil
 * 返回值：
 *     成功 - YES
 *     失败 - NO
 */
-(BOOL)mntProcessor: (nullable id<rlpsPipeProcessor>)processor
              error: (NSError  * _Nullable * _Nullable)err;

/*
 清空管道
 管道被清空时如果有阻塞的blockPop，都立即结束，并返回nil
 参数：
     (无)
 返回值：
     (无)
 */
-(void)clearPipe;

@end
