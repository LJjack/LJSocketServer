//
//  LJSocketIpAndPort.m
//  LJSocketServer
//
//  Created by 刘俊杰 on 15/11/26.
//  Copyright © 2015年 LJ. All rights reserved.
//

#import "LJSocketIpAndPort.h"
#import <arpa/inet.h>
@implementation LJSocketIpAndPort
#pragma mark - Ip And Port
#pragma mark Port
+ (UInt16)connectedPortFromNativeSocket4:(CFSocketNativeHandle)theNativeSocket
{
    struct sockaddr_in sockaddr4;
    socklen_t sockaddr4len = sizeof(sockaddr4);
    
    if(getpeername(theNativeSocket, (struct sockaddr *)&sockaddr4, &sockaddr4len) < 0)
    {
        return 0;
    }
    return [self portFromAddress4:&sockaddr4];
}
+ (UInt16)portFromAddress4:(struct sockaddr_in *)pSockaddr4
{
    return ntohs(pSockaddr4->sin_port);
}
#pragma mark Ip
+ (NSString *)connectedHostFromNativeSocket4:(CFSocketNativeHandle)theNativeSocket
{
    struct sockaddr_in sockaddr4;
    socklen_t sockaddr4len = sizeof(sockaddr4);
    
    if(getpeername(theNativeSocket, (struct sockaddr *)&sockaddr4, &sockaddr4len) < 0)
    {
        return nil;
    }
    return [self hostFromAddress4:&sockaddr4];
}
+ (NSString *)hostFromAddress4:(struct sockaddr_in *)pSockaddr4
{
    char addrBuf[INET_ADDRSTRLEN];
    
    if(inet_ntop(AF_INET, &pSockaddr4->sin_addr, addrBuf, (socklen_t)sizeof(addrBuf)) == NULL)
    {
        [NSException raise:NSInternalInconsistencyException format:@"Cannot convert IPv4 address to string."];
    }
    
    return [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
}
@end
