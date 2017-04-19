//
//  rlpsDWList.h
//  存储NSObject的双向链表
//
//  Created by Real on 2017/3/8.
//  Copyright © 2017年 Real. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * ---------------------------------------------------------------
 * 双向链表元素的容器类，非线程安全，基于ARC
 * 用于存储链表中的一个元素（NSObjcet），并提供前一个、后一个元素和容器的访问
 * ---------------------------------------------------------------
 */
@interface rlpsItemContainer : NSObject

// 所装载的元素
@property (readonly, strong, nullable) id item;
// 下一个container
@property (readonly, strong, nullable) rlpsItemContainer* next;
// 上一个container
@property (readonly, weak, nullable) rlpsItemContainer* last;

@end


/*
 * ---------------------------------------------------------------
 * 双向链表类，非线程安全，基于ARC
 * 链表中的每个元素（NSObject）都先放置到一个“rlpsItemContainer”中，然后挂接到链表上
 * 链表支持从头部和尾部两个方向上添加／移除元素
 * 链表不支持随机访问，链表的顺／逆序遍历操作由“rlpsItemContainer”实现
 * 链表对元素的所有操作均为“retain”，永远不会去“copy”一个元素
 * ---------------------------------------------------------------
 */
@interface rlpsDWList : NSObject

// 首元素
@property (readonly, nullable) id headItem;
// 尾元素
@property (readonly, nullable) id tailItem;
// 首容器
@property (readonly, nullable) rlpsItemContainer* headContainer;
// 尾容器
@property (readonly, nullable) rlpsItemContainer* tailContainer;
// 链表长度
@property (readonly) NSUInteger length;

/*
 向链表尾部添加新元素
 参数:
     (nonnull id) item , 需要添加到链表的新元素
 返回值:
     成功 - 新元素（非容器）
     失败 - nil
 */
-(nullable id) add2Tail: (nonnull id) item;

/*
 向链表头部添加新元素
 参数:
     (nonnull id) item , 需要添加到链表的新元素
 返回值:
     成功 - 新元素（非容器）
     失败 - nil
 */
-(nullable id) add2Head: (nonnull id) item;

/*
 从链表尾部移除一个元素
 参数: 
     (无)
 返回值:
     链表尾部的元素（非容器）, 如果链表为空返回nil
 */
-(nullable id) rmvFromTail;

/*
 从链表头部移除一个元素
 参数:
     (无)
 返回值:
     链表头部的元素（非容器）, 如果链表为空返回nil
 */
-(nullable id) rmvFromHead;

/*
 清空链表
 参数：
     (无)
 返回值：
     (无)
 */
-(void)eraseAll;

/*
 从链表尾部截取一段，返回截取出的子链表，原链表为截取后剩余的部分
 效率不高，链表尺寸较大时慎用
 参数：
     (NSUInteger)len , 截取的长度，0<len<self.length , 否则失败
 返回值：
     成功 - 子链表
     失败 - nil
 */
-(nullable rlpsDWList*) subListFromTail: (NSUInteger)len;

/*
 从链表头部截取一段，返回截取出的子链表，原链表为截取后剩余的部分
 效率不高，链表尺寸较大时慎用
 参数：
     (NSUInteger)len , 截取的长度，0<len<self.length , 否则失败
 返回值：
     成功 - 子链表
     失败 - nil
 */
-(nullable rlpsDWList*) subListFromHead: (NSUInteger)len;

/*
 将一个链表连接到另一个链表尾部
 参数：
     (nonnull rlpsDWList*)disappear , 被连接的链表 , 连接后被清空
     toMyTail:(nonnull rlpsDWList*)allAreMine , 连接的目标链表 , 连接后包含两个链表的所有元素
 返回值：
     成功 - allAreMine
     失败 - nil
 */
+(nullable rlpsDWList*)linkList:(nonnull rlpsDWList*)disappear toMyTail:(nonnull rlpsDWList*)allAreMine;


@end
