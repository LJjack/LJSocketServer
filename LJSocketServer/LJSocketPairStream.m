//
//  LJSocketPairStream.m
//  LJSocketServer
//
//  Created by 刘俊杰 on 15/11/26.
//  Copyright © 2015年 LJ. All rights reserved.
//
#define kSendOrReceiveBytesNumbers 2048 //2KB

#import "LJSocketPairStream.h"
#import "LJSocketIpAndPort.h"
#import "LJSocketHTTPResponse.h"
#import "LJSocketHandleHtml.h"
@interface LJSocketPairStream ()<NSStreamDelegate>
@property (assign,nonatomic) BOOL isReadData;
@property(strong,nonatomic,nullable) NSInputStream *inputStream;
@property(strong,nonatomic,nullable) NSOutputStream *outputStream;
@property (strong,nonatomic)NSMutableData *mBuffData;
@end
@implementation LJSocketPairStream
- (instancetype)init {
    if (self = [super init]) {
        self.mBuffData = [NSMutableData dataWithBytes:"" length:0];
    }
    return self;
}
- (void)createPairStreamWithSocketNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle {
//    NSString *ipAddress = [LJSocketIpAndPort connectedHostFromNativeSocket4:nativeSocketHandle];
//    UInt16 port = [LJSocketIpAndPort connectedPortFromNativeSocket4:nativeSocketHandle];
//    self.ipAndPort = [NSString stringWithFormat:@"%@:%d",ipAddress,port];
//    NSLog(@"接受一个新的客户端 %@",self.ipAndPort);
    CFReadStreamRef iStream;
    CFWriteStreamRef oStream;
    // 创建一个可读写的socket连接
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &iStream, &oStream);
    if (iStream && oStream)
    {
        // Ensure the CF & BSD socket is closed when the streams are closed.
        CFReadStreamSetProperty(iStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(oStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        NSInputStream *inputStream = CFBridgingRelease(iStream);
        NSOutputStream *outputStream = CFBridgingRelease(oStream);
        [self startStreamsWithInputStream:inputStream outputStream:outputStream];
    }
}
#pragma mark 设置流并打开
- (void)startStreamsWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *) outputStream {
    //SSL加密
        if (self.serverIdentity) {
            NSDictionary *setting = @{
                                      (__bridge NSString *) kCFStreamSSLIsServer:                 @YES,
                                      (__bridge NSString *) kCFStreamSSLCertificates:             @[ (__bridge id) self.serverIdentity ],
                                      (__bridge NSString *) kCFStreamSSLValidatesCertificateChain:@NO
                                      };
            BOOL successInput = [inputStream  setProperty:setting forKey:(__bridge NSString *) kCFStreamPropertySSLSettings];
            assert(successInput);
            BOOL successOutput = [outputStream  setProperty:setting forKey:(__bridge NSString *) kCFStreamPropertySSLSettings];
            assert(successOutput);
        }
    self.inputStream = inputStream;
    self.outputStream = outputStream;
}
- (void)runPairStream {
    // 设置代理，监听输入流和输出流中的变化
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    // Scoket是建立的长连接，需要将输入输出流添加到当前运行循环
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    [self.inputStream scheduleInRunLoop:currentRunLoop forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:currentRunLoop forMode:NSDefaultRunLoopMode];
    // 打开输入流和输出流，准备开始文件读写操作
    [self.inputStream open];
    [self.outputStream open];
}
- (void)stopPairStream{
    //清空buff
    [self resetMBuffData];
    //停止客户端
    if (self.inputStream) {
        [self.inputStream setDelegate:nil];
        [self.inputStream close];
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.inputStream = nil;
    }
    if (self.outputStream) {
        [self.outputStream setDelegate:nil];
        [self.outputStream close];
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.outputStream = nil;
    }
}
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted:{
            NSLog(@"连接完成 %p",self);
            if ([aStream isKindOfClass:[NSInputStream class]]) {
                _isReadData = NO;
            }
        }break;
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"有可读字节");
            NSInputStream  *iStream = nil;
            if ([aStream isKindOfClass:[NSInputStream class]]) {
                iStream = (NSInputStream *)aStream;
            }
            if (!iStream) return;
            if (!_isReadData&&[iStream hasBytesAvailable]) {
                [self resetMBuffData];
                NSTimer *inputTime = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(readBuffEnd:) userInfo:nil repeats:YES];
                NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
                [runLoop addTimer:inputTime forMode:NSDefaultRunLoopMode];

                _isReadData = YES;
            }
            // 读从服务器接收到得数据，从输入流中读取
            // 先开辟一段缓冲区以读取数据
            NSInteger bytesRead;
            uint8_t buffer[kSendOrReceiveBytesNumbers];
            bytesRead = [iStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead > 0) {
                [self.mBuffData appendBytes:buffer length:bytesRead];
            }
        }break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"可以写入数据");
            break;
        case NSStreamEventErrorOccurred: {
            NSLog(@"发生错误");
            if ([_requestDelegate respondsToSelector:@selector(socketPairStreamRequestDidReceiveError:)]) {
                [_requestDelegate socketPairStreamRequestDidReceiveError:self];
            }
        }break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"流结束");
            // 做善后工作
            if ([_requestDelegate respondsToSelector:@selector(socketPairStreamRequestDidFinish:)]) {
                [_requestDelegate socketPairStreamRequestDidFinish:self];
            }
            break;
        default:
            break;
    }
}
- (void)readBuffEnd:(NSTimer *)timer {
    if (![self.inputStream hasBytesAvailable]) {
        [timer invalidate];
        timer = nil;
        _isReadData = NO;
        //转发数据
        if (self.outputStream.streamStatus == NSStreamStatusOpen) {
            __weak typeof(self) wSelf = self;
            [LJSocketHandleHtml handleHtmlWithRequestData:self.mBuffData block:^(NSData *resData, NSString *contentType) {
                __strong typeof(self) sSelf = wSelf;
                NSData *responseData = [LJSocketHTTPResponse getResponseDataWithData:resData contentType:contentType];
                [sSelf sendMessage:responseData];
            }];
        }
    }
}
- (void)sendMessage:(NSData *)msgData {
    NSUInteger dataLen = msgData.length;
    NSUInteger sendDataLen = kSendOrReceiveBytesNumbers;
    NSUInteger yu = dataLen%sendDataLen;
    NSUInteger otherDataLen = 0;
    uint8_t buf[sendDataLen] ;
    while ([_outputStream hasSpaceAvailable]) {
        NSUInteger diff = dataLen - otherDataLen;
        if (diff == yu) {
            uint8_t oBuf[yu] ;
            [msgData getBytes:oBuf range:NSMakeRange(otherDataLen,yu)];
            otherDataLen += [_outputStream write:oBuf maxLength:sizeof(oBuf)];
        }else {
            [msgData getBytes:buf range:NSMakeRange(otherDataLen,sendDataLen)];
            otherDataLen += [_outputStream write:buf maxLength:sizeof(buf)];
        }
        if (otherDataLen == dataLen) {
            break;
        }
    }
}
- (void)resetMBuffData {
    if (self.mBuffData.length>0) {
        [self.mBuffData resetBytesInRange:NSMakeRange(0, self.mBuffData.length)];
        [self.mBuffData setLength:0];
    }
}
- (void)dealloc {
    [self stopPairStream];
}
@end
