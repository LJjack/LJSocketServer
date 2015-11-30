//
//  LJGzip.h
//  LJSocketServer
//
//  Created by 刘俊杰 on 15/11/30.
//  Copyright © 2015年 LJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LJGzip : NSObject
/*
 Gzip压缩
 **/
+ (NSData *)compressData:(NSData *)data;

/*
 Gzip解压缩
 **/
+ (NSData *)decompressData:(NSData *)data;
@end
