//
//  LJSocketPairStream.h
//  LJSocketServer
//
//  Created by 刘俊杰 on 15/11/26.
//  Copyright © 2015年 LJ. All rights reserved.
//
/**
 *  handle Socket stream
 *  处理socket输入输出流
 */

#import <Foundation/Foundation.h>
@class LJSocketPairStream;
@protocol LJSocketPairStreamDelegate <NSObject>

- (void)socketPairStreamRequestDidFinish:(LJSocketPairStream *_Nonnull)request;
- (void)socketPairStreamRequestDidReceiveError:(LJSocketPairStream *_Nonnull)request;

@end
@interface LJSocketPairStream : NSObject
@property(copy,nonatomic,nonnull) NSString *ipAndPort;
@property(assign,nonatomic,nullable) id<LJSocketPairStreamDelegate> requestDelegate;
@property (nonatomic, assign,nullable) SecIdentityRef    serverIdentity __attribute(( NSObject ));
- (void)createPairStreamWithSocketNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle;
- (void)stopPairStream;
@end
