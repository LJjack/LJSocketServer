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
    NSLog(@"==%@",[[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding]);
    CFHTTPMessageRef message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, YES);
    CFHTTPMessageAppendBytes(message, [requestData bytes], requestData.length);
    CFURLRef URLRef = CFHTTPMessageCopyRequestURL(message);
    CFRelease(message);
    CFStringRef urlStr = CFURLGetString(URLRef);
    NSString *htmlString = (__bridge NSString *)(urlStr);
    htmlString = [htmlString substringFromIndex:1];
    NSRange range = [htmlString rangeOfString:@"?"];
    if (range.length>0) {
        htmlString = [htmlString substringToIndex:range.location];
    }
    if (!htmlString||[htmlString isEqualToString:@""]) {
        htmlString = @"index.html";
    }
    NSLog(@"**%@**",htmlString);
    [self selectedHtmlWithHtmlName:htmlString];
    
}
+ (void)selectedHtmlWithHtmlName:(NSString *)htmlString {
    NSURL *htmlURL = [[NSBundle mainBundle] URLForResource:htmlString withExtension:nil];
    NSData *htmlData = nil;
    NSString *contentType = nil;
    if ([htmlString hasSuffix:@"html"]) {
        htmlData = [NSData dataWithContentsOfURL:htmlURL];
        contentType = @"text/html;charset=utf-8";
    }else if ([htmlString hasSuffix:@"png"]) {
        htmlData = [NSData dataWithContentsOfURL:htmlURL];
        contentType = @"image/png";
    }
    
    if (_block) {
        _block(htmlData,contentType);
    }
}
@end
