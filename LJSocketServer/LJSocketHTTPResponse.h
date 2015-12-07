//
//  LJSocketHTTPResponse.h
//  LJSocketServer
//
//  Created by 刘俊杰 on 15/11/26.
//  Copyright © 2015年 LJ. All rights reserved.
//
/**
 *  获取http响应报头
 */
#import <Foundation/Foundation.h>

@interface LJSocketHTTPResponse : NSObject
+ ( NSData * _Nullable)getResponseDataWithData:( NSData * _Nonnull )data contentType:(NSString *_Nonnull)contentType;
@end
