//
//  XTYCrashFinder.h
//  XTYCrashFinder
//
//  Created by Mr.Sunday on 16/8/3.
//  Copyright © 2016年 Sunday. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XTYCrashFinder : NSObject

+ (BOOL)installNSExceptionHandler;
+ (void)unInstallNSExceptionHandler;

@end