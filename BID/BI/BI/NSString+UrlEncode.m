//
//  NSString+UrlEncode.m
//  转换带有特殊符号的url参数
//
//  Created by 毅 张 on 12-7-6.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "NSString+UrlEncode.h"

@implementation NSString (UrlEncode)

- (NSString*)stringByURLEncodingStringParameter{
    
    NSString *resultStr = self;

    CFStringRef originalString = (__bridge CFStringRef) self;
    CFStringRef leaveUnescaped = CFSTR(" ");
    CFStringRef forceEscaped = CFSTR("!*'();:@&=+$,/?%#[]");
    
    CFStringRef escapedStr;
    escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                         originalString,
                                                         leaveUnescaped, 
                                                         forceEscaped,
                                                         kCFStringEncodingUTF8);
    
    if( escapedStr ){
        NSMutableString *mutableStr = [NSMutableString stringWithString:(__bridge NSString *)escapedStr];
        CFRelease(escapedStr);
        
        [mutableStr replaceOccurrencesOfString:@" " withString:@"%20" options:0 range:NSMakeRange(0, [mutableStr length])];
        
        resultStr = mutableStr;
    }
    return resultStr;
}

@end
