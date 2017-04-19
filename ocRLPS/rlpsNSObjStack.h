//
//  rlpsNSObjStack.h
//  面向NSObject的“栈”，没什么用 - just for fun
//
//  Created by Real on 2017/3/14.
//  Copyright © 2017年 Real. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * ---------------------------------------------------------------
 * 面向NSObject的栈，数据存储遵循后进先出的原则，数据必须遵守NSCoding协议
 * 线程安全，基于ARC／GCD
 * 入栈需要指定数据数据和时机
 * 出栈只需指定时机，自动将最后一批入栈的数据恢复到原变量
 * 使用者需要保证出栈时目标变量的有效性（生命周期），否则会出错
 * ---------------------------------------------------------------
 */
@interface rlpsNSObjStack : NSObject

/*
 暂存数据，在此刻变量的值被序列化并缓存
 不要跨作用域暂存，即离开当前作用域前已经暂存的数据要么释放要么入栈
 或者使用作用域安全的宏PUSH_AUTORELEASE／PUSH_AUTOCOMMIT
 */
-(BOOL)push: (nonnull id)item error:(NSError  * _Nullable * _Nullable)err;

/*
 将暂存的数据提交入栈
 */
-(void)commit;

/*
 将暂存的数据释放
 */
-(void)release;

/*
 将最后入栈的一批数据出栈
 */
-(BOOL)pop: (NSError  * _Nullable * _Nullable)err;

@end

/*
 作用域安全push
 使用该宏暂存的数据，离开当前作用域时如果未提交将自动从暂存数据中清除
 */
#define PUSH_AUTORELEASE(stack, item, err) \
rlpsARA* ara##_##__LINE__=[[rlpsARA alloc] initWithStack:stack]; \
if(![stack push: item error: err]) {ara##_##__LINE__=nil};

/*
 作用域安全push
 使用该宏暂存的数据，离开当前作用域时如果未提交将自动提交入栈
 */
#define PUSH_AUTOCOMMIT(stack, item, err) \
rlpsARA* aca##_##__LINE__=[[rlpsACA new] initWithStack:stack]; \
if(![stack push: item error: err]) {ara##_##__LINE__=nil};


