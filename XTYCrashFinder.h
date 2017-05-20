//
//  XTYCrashFinder.h
//  XTYCrashFinder
//
//  Created by Mr.Sunday on 16/8/3.
//  Copyright © 2016年 Sunday. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XTYCrashFinder : NSObject

/**
 *  install the XTYCrashFinder, you should use this method at the end of the appdidLanch method.
 *  This is because some other third party library may also collect crash information.
 */
+ (BOOL)installNSExceptionHandler;
+ (void)unInstallNSExceptionHandler;

@end
