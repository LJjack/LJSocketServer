//
//  LJSocketServer.h
//  df
//
//  Created by 刘俊杰 on 15/11/11.
//  Copyright © 2015年 LJ. All rights reserved.
//
/**
 *  处理socket事件
 */
#import <Foundation/Foundation.h>
@interface LJSocketServer : NSObject

@property (nonatomic, assign,nullable) SecIdentityRef    serverIdentity __attribute(( NSObject ));
- (_Nonnull instancetype)initWithPort:(UInt16)port;
-(void) startSocketServer;
- (void)stopAllClientConnection;
- (void)stopSocketConnection;
@end
