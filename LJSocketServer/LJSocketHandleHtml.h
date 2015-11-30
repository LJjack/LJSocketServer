//
//  LJSocketHandleHtml.h
//  LJSocketServer
//
//  Created by 刘俊杰 on 15/11/27.
//  Copyright © 2015年 LJ. All rights reserved.
//
/*
 * 解析http请求报头
 */
#import <Foundation/Foundation.h>
typedef void(^LJSocketHandleHtmlBlock)(NSData *responseData);
@interface LJSocketHandleHtml : NSObject
+ (void)handleHtmlWithRequestData:(NSData *)requestData block:(LJSocketHandleHtmlBlock)block;
@end
