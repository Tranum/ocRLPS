//
//  rlpsLog.h
//  两套分级日志定义： 宏定义一套，函数定义一套
//
//  Created by Real on 16/9/13.
//  Copyright © 2016年 DWTECH. All rights reserved.
//

#ifndef rlps_log_h
#define rlps_log_h


/*
 * 调试信息输出 宏定义
 * 调试信息不是程序的固定日志输出，完成调试后应及时关闭
 */

/* 调试信息开关 */
#define RLPS_DEBUG_OPEN

/* 调试宏定义 */
#ifdef RLPS_DEBUG_OPEN
#define LOG_DEBUG(x) NSLog(x)
#define LOG_DEBUGv(x, ...) NSLog(x, __VA_ARGS__)
#endif
#ifndef RLPS_DEBUG_OPEN
#define LOG_DEBUG(x) ;
#define LOG_DEBUGv(x, ...) ;
#endif


/*
 * 分级日志 宏形式
 * 分为四个级别：
 *     信息 -- 程序运行的正常状态信息，供分析程序逻辑
 *     警告 -- 程序可能遇到了异常或非期望的状态
 *     错误 -- 程序运行发生了错误，但不影响程序继续提供服务
 *     致命 -- 程序发生致命错误，可能崩溃，无法继续提供服务
 * 注释掉对应的级别，即可屏蔽此级别的日志
 */

/* 日志开关 */
#define RLPS_LOG_INFO
#define RLPS_LOG_WARN
#define RLPS_LOG_ERROR
#define RLPS_LOG_FATAL

/* INFO */
#ifdef RLPS_LOG_INFO
#define LOG_INFO(x) NSLog(x)
#define LOG_INFOv(x, ...) NSLog(x, __VA_ARGS__)
#endif
#ifndef RLPS_LOG_INFO
#define LOG_INFO(x) ;
#define LOG_INFOv(x, ...) ;
#endif
/* WARNING */
#ifdef RLPS_LOG_WARN
#define LOG_WARN(x) NSLog(x)
#define LOG_WARNv(x, ...) NSLog(x, __VA_ARGS__)
#endif
#ifndef RLPS_LOG_WARN
#define LOG_WARN(x) ;
#define LOG_WARNv(x, ...) ;
#endif
/* ERROR */
#ifdef RLPS_LOG_ERROR
#define LOG_ERROR(x) NSLog(x)
#define LOG_ERRORv(x, ...) NSLog(x, __VA_ARGS__)
#endif
#ifndef RLPS_LOG_ERROR
#define LOG_ERROR(x) ;
#define LOG_ERRORv(x, ...) ;
#endif
/* FATAL */
#ifdef RLPS_LOG_FATAL
#define LOG_FATAL(x) NSLog(x)
#define LOG_FATALv(x, ...) NSLog(x, __VA_ARGS__)
#endif
#ifndef RLPS_LOG_FATAL
#define LOG_FATAL(x) ;
#define LOG_FATALv(x, ...) ;
#endif




/*
 * 分级日志 函数形式
 * 分为四个级别：
 *     信息 -- 程序运行的正常状态信息，供分析程序逻辑
 *     警告 -- 程序可能遇到了异常或非期望的状态
 *     错误 -- 程序运行发生了错误，但不影响程序继续提供服务
 *     致命 -- 程序发生致命错误，可能崩溃，无法继续提供服务
 */

/* 日志级别 */
#define RLPS_LLEVEL_INFO    0x01
#define RLPS_LLEVEL_WARN    0x02
#define RLPS_LLEVEL_ERROR   0x04
#define RLPS_LLEVEL_FATAL   0x08

/* 日志开关，默认全部打开 */
void set_log_level(uint8_t level);

/* INFO LOG */
FOUNDATION_EXPORT void log_info(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
/* WARN LOG */
FOUNDATION_EXPORT void log_warn(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
/* ERROR LOG */
FOUNDATION_EXPORT void log_error(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
/* FATAL LOG */
FOUNDATION_EXPORT void log_fatal(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);


#endif /* rlps_log_h */
