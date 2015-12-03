//
//  LJSocketHTTPResponse.m
//  LJSocketServer
//
//  Created by 刘俊杰 on 15/11/26.
//  Copyright © 2015年 LJ. All rights reserved.
//

#import "LJSocketHTTPResponse.h"
#import "LJGzip.h"
@implementation LJSocketHTTPResponse
+ (NSData *)getResponseDataWithData:(NSData *)data {
    if (data) {
        data = [LJGzip compressData:data];//压缩
    }
    
    CFHTTPMessageRef message =CFHTTPMessageCreateResponse(
                                                          kCFAllocatorDefault,
                                                          200,
                                                          (__bridge CFStringRef)@"OK",
                                                          kCFHTTPVersion1_1);
    CFHTTPMessageSetHeaderFieldValue(message,
                                     (__bridge CFStringRef)@"Content-Type",
                                     (__bridge CFStringRef)@"text/html;charset=utf-8");
    CFHTTPMessageSetHeaderFieldValue(message,
                                     (__bridge CFStringRef)@"Connection",
                                     (__bridge CFStringRef)@"close");
    CFHTTPMessageSetHeaderFieldValue(message,
                                     (__bridge CFStringRef)@"Content-Length",
                                     (__bridge CFStringRef)[NSString stringWithFormat:@"%lu",(unsigned long)[data length]]);
    CFHTTPMessageSetHeaderFieldValue(message,
                                     (__bridge CFStringRef)@"Content-Encoding",
                                     (__bridge CFStringRef)@"gzip");
    CFHTTPMessageSetBody(message, (__bridge CFDataRef)(data));
    
    CFDataRef headerData = CFHTTPMessageCopySerializedMessage(message);
    CFRelease(message);
    return CFBridgingRelease(headerData);
}
@end
