//
//  ViewController.m
//  LJSocketServer
//
//  Created by 刘俊杰 on 15/11/13.
//  Copyright © 2015年 LJ. All rights reserved.
//

#import "ViewController.h"
#import "LJSocketServer.h"

@implementation ViewController
{
    LJSocketServer *_socketServer;
    BOOL isOpenServer;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _socketServer = [[LJSocketServer alloc] init];
    //此处时https
    //公钥
//    NSString *certificatePath = [[NSBundle mainBundle] pathForResource:@"public_key" ofType:@"der"];
//    NSData *certData = [[NSData alloc] initWithContentsOfFile:certificatePath];
//    CFDataRef certDataRef = (__bridge CFDataRef)certData;
//    SecCertificateRef cert = SecCertificateCreateWithData(NULL, certDataRef);
//
//    SecIdentityRef serverIdentityRef;
//    SecIdentityCreateWithCertificate(NULL, cert, &serverIdentityRef);
//    
//    _socketServer.serverIdentity = serverIdentityRef;
//    CFRelease(serverIdentityRef);
//    CFRelease(cert);
}
// 开启服务器
- (IBAction)openServer:(NSButton *)sender {
    if (!isOpenServer) {
        [_socketServer startSocketServer];
    }else {
        [_socketServer stopSocketConnection];
    }
    isOpenServer = !isOpenServer;
    [sender setTitle:!isOpenServer?@"开启服务器":@"停止服务器"];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
