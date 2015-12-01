//
//  LJSocketServer.m
//  df
//
//  Created by 刘俊杰 on 15/11/11.
//  Copyright © 2015年 LJ. All rights reserved.
//
/*
 */
#import "LJSocketServer.h"
#import "LJSocketPairStream.h"
#import <netinet/in.h>
#import <arpa/inet.h>
@interface LJSocketServer ()<NSStreamDelegate>
@property (strong,nonatomic) NSMutableArray *pairStreamMArray;
@property (nonatomic,assign) UInt16 port;
////////////////socket回调函数//////////////////////
static void MyCFSocketCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);
@end

@implementation LJSocketServer
{
    CFSocketRef        _theSocket4;
    CFRunLoopSourceRef _theSource4;
    CFSocketContext    _theContext;
    NSData            *_theAddress4;
}

- (instancetype)initWithPort:(UInt16)port {
    if (self = [super init]) {
        self.port = port?port:8011;
        self.pairStreamMArray = [NSMutableArray array];
        _theSocket4 = NULL;
        _theSource4 = NULL;
        //创建socket上下文
        _theContext.version = 0;// 结构体的版本，必须为0
        _theContext.info = (__bridge void *)(self);
        _theContext.retain = nil;
        _theContext.release = nil;
        _theContext.copyDescription = nil;
        //设置地址
        struct sockaddr_in nativeAddr4;
        nativeAddr4.sin_len = sizeof(nativeAddr4);
        nativeAddr4.sin_family = AF_INET;
        nativeAddr4.sin_port = htons(self.port);//端口号
        nativeAddr4.sin_addr.s_addr = htonl(INADDR_ANY);
        memset(&nativeAddr4.sin_zero, 0, sizeof(nativeAddr4.sin_zero));
        _theAddress4 = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
    }
    return self;
}
- (CFSocketRef)newAcceptSocketForAddress:(NSData *)addr {
    
    struct sockaddr *pSocketAddr = (struct sockaddr*)[addr bytes];
    int addressFamily = pSocketAddr->sa_family;
    
    CFSocketRef theSocket = CFSocketCreate(kCFAllocatorDefault, addressFamily, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, MyCFSocketCallback, &_theContext);
    return theSocket;
}
- (BOOL)setupNewSocket {
    if (!_theAddress4) return NO;
    if (_theSocket4) [self stopSocketConnection];
    _theSocket4 = [self newAcceptSocketForAddress:_theAddress4];
    if (!_theSocket4) return NO;
    
    int optval = 1;
    setsockopt(CFSocketGetNative(_theSocket4), SOL_SOCKET, SO_REUSEADDR, // 允许重用本地地址和端口
               (void *)&optval, sizeof(optval));
    
    if (kCFSocketSuccess != CFSocketSetAddress(_theSocket4, (__bridge CFDataRef)_theAddress4))
    {
        NSLog(@"Bind to address failed!");
        if (_theSocket4)
            CFSocketInvalidate(_theSocket4);
            CFRelease(_theSocket4);
            _theSocket4 = NULL;
            return NO;
    }
    [self attachSocketToRunLoopCreateAndAddSource];
    return YES;
}
///////////////////
#pragma mark  Run Loop Create And Add Source
///////////
- (void)attachSocketToRunLoopCreateAndAddSource {
    if (_theSource4) [self removeRunLoopSource];
    if (_theSocket4) {
        _theSource4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _theSocket4, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), _theSource4, kCFRunLoopCommonModes);
        CFRunLoopRun();    // 运行当前线程的CFRunLoop对象
    }
}
#pragma mark Run Loop Remove Source
- (void)removeRunLoopSource {
    if (_theSource4) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _theSource4, kCFRunLoopCommonModes);
        CFRunLoopStop(CFRunLoopGetCurrent());
        CFRelease(_theSource4);
        _theSource4 = NULL;
    }
}
// 开辟一个线程线程函数中
-(void) startSocketServer
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL res = [self  setupNewSocket];
        if (res) {
            NSLog(@"socket server success");
        }else {
            [self stopSocketConnection];
            NSLog(@"socket server fail");
        }
    });
    
}
- (void)doAcceptFromSocket:(CFSocketRef)parentSocket
       withNewNativeSocket:(CFSocketNativeHandle)nativeSocketHandle {
    if (nativeSocketHandle) {
        
        LJSocketPairStream *pairStream = [[LJSocketPairStream alloc] init];
        pairStream.serverIdentity = self.serverIdentity;
        [pairStream createPairStreamWithSocketNativeSocketHandle:nativeSocketHandle];
        [self.pairStreamMArray addObject:pairStream];
    }
}
- (void)doCFSocketCallback:(CFSocketCallBackType)type
                 forSpcket:(CFSocketRef)socket
               withAddress:(NSData *)address
                  withData:(const void*)data
{
    switch (type) {
        case kCFSocketConnectCallBack: {
            [self stopSocketConnection];
        }break;
        case kCFSocketAcceptCallBack: {
            // 本地套接字句柄
            CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
            [self doAcceptFromSocket:socket withNewNativeSocket:nativeSocketHandle];
        }break;
        default:
            break;
    }
}
- (void)stopAllClientConnection {
    if (self.pairStreamMArray.count>0) {
        for (LJSocketPairStream *pairStream in self.pairStreamMArray) {
            [pairStream stopPairStream];
        }
        [self.pairStreamMArray removeAllObjects];
    }
}
#pragma mark stop socket
- (void)stopSocketConnection {
    [self stopAllClientConnection];
    [self removeRunLoopSource];
    if (_theSocket4) {
        CFSocketInvalidate(_theSocket4);
        CFRelease(_theSocket4);
        _theSocket4 = NULL;
    }
}
- (void)dealloc {
    [self stopSocketConnection];
}
@end
////////////////socket回调函数////////////////////
static void MyCFSocketCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    @autoreleasepool {
        LJSocketServer *server = (__bridge LJSocketServer *)info;
        NSData *inAddress = [(__bridge NSData *)address copy];
        [server doCFSocketCallback:type forSpcket:socket withAddress:inAddress withData:data];
    }
    
}