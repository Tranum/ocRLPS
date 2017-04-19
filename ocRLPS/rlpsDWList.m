//
//  rlpsDWList.m
//  存储NSObject的双向链表，非线程安全
//
//  Created by Real on 2017/3/8.
//  Copyright © 2017年 Real. All rights reserved.
//

#import "rlpsDWList.h"

#pragma mark 1 rlpsItemContainer realize

#pragma mark 1.1 class extension
@interface rlpsItemContainer ()
@property (strong, nullable) id item;
@property (strong, nullable) rlpsItemContainer* next;
@property (weak, nullable) rlpsItemContainer* last;
@end

@implementation rlpsItemContainer

#pragma mark 1.2 property function
@synthesize item, next, last;

#pragma mark 1.3 construct & destruct & other rewrite
-(instancetype) init
{
    if (self = [super init])
    {
        self.item = nil;
        self.next = nil;
        self.last = nil;
    }
    return self;
}

-(instancetype) initWithNsobj: (nullable id) nsObj
                    withNext: (nullable rlpsItemContainer*) nextContainer
                    withLast: (nullable rlpsItemContainer*) lastContainer
{
    if (self = [super init])
    {
        self.item = nsObj;
        self.last = lastContainer;
        self.next = nextContainer;
    }
    return self;
}

-(NSString*) description
{
    return [[NSString alloc] initWithFormat:@"Container '%lu' , next -> %@ , last -> %@"
            , (unsigned long)[self hash]
            , self.next?[[NSString alloc] initWithFormat:@"%lu", (unsigned long)[self.next hash]]:@"(null)"
            , self.last?[[NSString alloc] initWithFormat:@"%lu", (unsigned long)[self.last hash]]:@"(null)"];
}

-(void)dealloc
{
    self.item = nil;
    self.last = nil;
    self.next = nil;
}

@end


#pragma mark 2 rlpsDWList

#pragma mark 2.1 class extension
@interface rlpsDWList ()
@property (retain, nullable) rlpsItemContainer* headContainer;
@property (retain, nullable) rlpsItemContainer* tailContainer;
@property (assign) NSUInteger length;
@end


@implementation rlpsDWList

#pragma mark 2.2 property function
@synthesize headContainer, tailContainer, length;

-(nullable id)headItem
{
    if (0==self.length)
    {
        return nil;
    }
    
    id tmpItem = self.headContainer.item;
    if ([tmpItem isEqual: [NSNull null]])
    {
        tmpItem = nil;
    }
    
    return tmpItem;
}
-(nullable id)tailItem
{
    if (0==self.length)
    {
        return nil;
    }
    
    id tmpItem = self.tailContainer.item;
    if ([tmpItem isEqual: [NSNull null]])
    {
        tmpItem = nil;
    }
    
    return tmpItem;
}

#pragma mark 2.3 construct & destruct & other rewrite
-(instancetype) init
{
    if (self = [super init])
    {
        self.headContainer = nil;
        self.tailContainer = nil;
        self.length  = 0;
    }
    return self;
}

-(void)dealloc
{
    self.length = 0;
    self.tailContainer = nil;
    self.headContainer = nil;
}

-(NSString*)description
{
    return [[NSString alloc] initWithFormat:@"rlpsDWList '%lu':\nlength - %lu\nhead - %@\ntail - %@"
            , (unsigned long)[self hash]
            , (unsigned long)self.length
            , self.headContainer
            , self.tailContainer];
}

#pragma mark 4. class function
/*向链表尾部添加新元素*/
-(nullable id) add2Tail: (nonnull id) item
{
    if (nil==item) return nil;
    
    rlpsItemContainer* newContainer = [[rlpsItemContainer alloc] initWithNsobj: item
                                                                      withNext: nil
                                                                      withLast: self.tailContainer];
    if (nil==newContainer) return nil;
    
    if (0==self.length)
    {
        self.headContainer = newContainer;
        self.tailContainer = newContainer;
    }
    else
    {
        self.tailContainer.next = newContainer;
        self.tailContainer = newContainer;
    }
    
    self.length += 1;
    
    return item;
}

/* 向链表头部添加新元素 */
-(nullable id) add2Head: (nonnull id) item
{
    if (nil==item) return nil;
    
    rlpsItemContainer* newContainer = [[rlpsItemContainer alloc] initWithNsobj: item
                                                                      withNext: self.headContainer
                                                                      withLast: nil];
    if (nil==newContainer) return nil;
    
    if (0==self.length)
    {
        self.headContainer = newContainer;
        self.tailContainer = newContainer;
    }
    else
    {
        self.headContainer.last = newContainer;
        self.headContainer = newContainer;
    }
    
    self.length += 1;
    
    return item;
}

/*从链表尾部移除一个元素*/
-(nullable id) rmvFromTail
{
    if (0==self.length) return nil;
    
    rlpsItemContainer* tmpContainer = self.tailContainer;
    
    self.tailContainer = self.tailContainer.last;
    self.tailContainer.next = nil;
    self.length -= 1;
    
    if (0==self.length) self.headContainer = nil; // 处理移除后一个元素都不剩的特殊情况
    
    return tmpContainer.item;
}

/*从链表头部移除一个元素*/
-(nullable id) rmvFromHead
{
    if (0==self.length) return nil;
    
    rlpsItemContainer* tmpContainer = self.headContainer;
    
    self.headContainer = self.headContainer.next;
    self.headContainer.last = nil;
    self.length -= 1;
    
    if (0==self.length) self.tailContainer = nil; // 处理移除后一个元素都不剩的特殊情况
    
    return tmpContainer.item;
}

/* 清空链表 */
-(void)eraseAll
{
    if (0==self.length) return;
    
    self.length = 0;
    self.tailContainer = nil;
    self.headContainer = nil;
}

/* 从链表尾部截取一段 */
-(nullable rlpsDWList*) subListFromTail: (NSUInteger)len
{
    if (0==len || len>=self.length)
    {
        return nil;
    }
    
    // 判断哪边短一些
    BOOL inverting = NO;
    NSUInteger tmpLen = len;
    if (len>(self.length)>>1)
    {
        tmpLen = self.length - len;
        inverting = YES;
    }
    
    // 从短的一侧查找截取点
    rlpsDWList* cutResult = [rlpsDWList new];
    rlpsItemContainer* cutAt = nil;
    if (inverting)
    {
        cutAt = self.headContainer;
        for (NSUInteger i=1; i<tmpLen; ++i)
        {
            cutAt = cutAt.next;
        }
    }
    else
    {
        cutAt = self.tailContainer;
        for (NSUInteger i=0; i<tmpLen; ++i)
        {
            cutAt = cutAt.last;
        }
    }
    
    // 截取
    cutResult.headContainer = cutAt.next;
    cutResult.headContainer.last = nil;
    cutResult.tailContainer = self.tailContainer;
    cutResult.length = len;
    self.tailContainer = cutAt;
    self.tailContainer.next = nil;
    self.length -= len;
    
    return cutResult;
}

/* 从链表头部截取一段 */
-(nullable rlpsDWList*) subListFromHead: (NSUInteger)len
{
    if (0==len || len>=self.length)
    {
        return nil;
    }
    
    // 判断哪边短一些
    BOOL inverting = NO;
    NSUInteger tmpLen = len;
    if (len>(self.length)>>1)
    {
        tmpLen = self.length - len;
        inverting = YES;
    }
    
    // 从短的一侧查找截取点
    rlpsDWList* cutResult = [rlpsDWList new];
    rlpsItemContainer* cutAt = nil;
    if (inverting)
    {
        cutAt = self.tailContainer;
        for (NSUInteger i=1; i<tmpLen; ++i)
        {
            cutAt = cutAt.last;
        }
    }
    else
    {
        cutAt = self.headContainer;
        for (NSUInteger i=0; i<tmpLen; ++i)
        {
            cutAt = cutAt.next;
        }
    }
    
    // 截取
    cutResult.headContainer = self.headContainer;
    cutResult.tailContainer = cutAt.last;
    cutResult.tailContainer.next = nil;
    cutResult.length = len;
    self.headContainer = cutAt;
    self.headContainer.last = nil;
    self.length -= len;
    
    return cutResult;
}

/* 将一个链表连接到另一个链表尾部 */
+(nullable rlpsDWList*)linkList:(nonnull rlpsDWList*)disappear toMyTail:(nonnull rlpsDWList*)allAreMine
{
    if (nil==allAreMine) return nil;
    if (![allAreMine isKindOfClass: [rlpsDWList class]]) return nil;
    
    if (nil==disappear)  return allAreMine;
    if (![disappear  isKindOfClass: [rlpsDWList class]]) return nil;
    
    if (0==disappear.length) return allAreMine;
    
    if (0==allAreMine.length)
    {
        allAreMine.headContainer = disappear.headContainer;
    }
    else
    {
        disappear.headContainer.last  = allAreMine.tailContainer;
        allAreMine.tailContainer.next = disappear.headContainer;
    }
    
    allAreMine.tailContainer = disappear.tailContainer;
    allAreMine.length += disappear.length;
    disappear.headContainer = nil;
    disappear.tailContainer = nil;
    disappear.length = 0;
    
    return nil;
}



@end
