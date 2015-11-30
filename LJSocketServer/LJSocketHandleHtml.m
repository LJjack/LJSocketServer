//
//  LJSocketHandleHtml.m
//  LJSocketServer
//
//  Created by 刘俊杰 on 15/11/27.
//  Copyright © 2015年 LJ. All rights reserved.
//

#import "LJSocketHandleHtml.h"

@implementation LJSocketHandleHtml
static LJSocketHandleHtmlBlock _block;
+ (void)handleHtmlWithRequestData:(NSData *)requestData block:(LJSocketHandleHtmlBlock)block{
    _block = block;
    NSInteger index = 0;
    NSUInteger index0 = 0,index1 = requestData.length;
    uint8_t *mByte = (uint8_t *)requestData.bytes;
    
    while (index != requestData.length) {
        if (mByte[index] == '/') index0 = index+1;
        if (mByte[index] == 'H') {
            index1 = index;
            break;
        }
        index ++;
    }
    NSData *data = [requestData subdataWithRange:NSMakeRange(index0, index1-index0-1)];
    NSString *htmlString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSRange range = [htmlString rangeOfString:@"?"];
    if (range.length>0) {
        htmlString = [htmlString substringToIndex:range.location];
    }
    if (!htmlString||[htmlString isEqualToString:@""]) {
        htmlString = @"index.html";
    }
    [self selectedHtmlWithHtmlName:htmlString];
}
+ (void)selectedHtmlWithHtmlName:(NSString *)htmlString {
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:htmlString ofType:nil];
    NSData *htmlData = [NSData dataWithContentsOfFile:htmlPath];
    if (_block) {
        _block(htmlData);
    }
}
@end
