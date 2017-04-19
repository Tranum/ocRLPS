//
//  rlpsLog.m
//  分级日志函数的实现
//
//  Created by Real on 16/9/13.
//  Copyright © 2016年 DWTECH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "rlpsLog.h"

/* 日志级别状态 */
static uint8_t _level_flag = RLPS_LLEVEL_INFO|RLPS_LLEVEL_WARN|RLPS_LLEVEL_ERROR|RLPS_LLEVEL_FATAL;

/* 设置日志级别 */
void set_log_level(uint8_t level)
{
    _level_flag = level&0x0f;
}

/* INFO LOG */
void log_info(NSString *format, ...)
{
    if (0==(_level_flag&RLPS_LLEVEL_INFO)) return;
    
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
}

/* WARN LOG */
void log_warn(NSString *format, ...)
{
    if (0==(_level_flag&RLPS_LLEVEL_WARN)) return;
    
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
}

/* ERROR LOG */
void log_error(NSString *format, ...)
{
    if (0==(_level_flag&RLPS_LLEVEL_ERROR)) return;
    
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
}

/* FATAL LOG */
void log_fatal(NSString *format, ...)
{
    if (0==(_level_flag&RLPS_LLEVEL_FATAL)) return;
    
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
}
