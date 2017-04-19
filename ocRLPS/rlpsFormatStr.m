//
//  rlpsFormatStr.m
//  ocRLPS
//
//  Created by Real on 2017/3/17.
//  Copyright © 2017年 DWTECH. All rights reserved.
//

#import "rlpsFormatStr.h"

/* 二进制数据格式化成字符串 */
NSString* hex2str(NSData* data)
{
    if (nil==data) return @"";
    
    NSUInteger count = data.length;
    if (0==count) return @"";
    
    NSMutableString* tmpstr = [[NSMutableString alloc] initWithCapacity:51*(1+(count>>4))];
    NSUInteger Len = 16;
    uint8_t* phead = (uint8_t*)[data bytes];
    for (NSUInteger i=0 ; i<count ; i++)
    {
        if (i>0 && 0==i%(Len/2) && 0!=i%Len) [tmpstr appendString:@"  "];
        if (i>0 && 0==i%Len) [tmpstr appendString:@"\n"];
        
        [tmpstr appendFormat:@"%02x ", *(phead+i)];
    }
    
    return tmpstr;
}
