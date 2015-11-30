//
//  LJSocketIpAndPort.h
//  LJSocketServer
//
//  Created by 刘俊杰 on 15/11/26.
//  Copyright © 2015年 LJ. All rights reserved.
//
/**
 *  获取联结服务器的IP地址和端口
 */
#import <Foundation/Foundation.h>

@interface LJSocketIpAndPort : NSObject
+ (NSString *)connectedHostFromNativeSocket4:(CFSocketNativeHandle)theNativeSocket;
+ (UInt16)connectedPortFromNativeSocket4:(CFSocketNativeHandle)theNativeSocket;
@end
