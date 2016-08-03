//
//  XTYCrashFinderItem.h
//  XTYCrashFinder
//
//  Created by Mr.Sunday on 16/8/3.
//  Copyright © 2016年 Sunday. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XTYCrashFinderItem : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *app_ver;
@property (nonatomic, strong) NSString *crash_id;
@property (nonatomic, strong) NSString *crash_time;
@property (nonatomic, strong) NSString *crash_name;
@property (nonatomic, strong) NSString *page_name;
@property (nonatomic, strong) NSString *stack_info;
@property (nonatomic, strong) NSString *dsym_uuid;
@property (nonatomic, strong) NSString *base_address;
@property (nonatomic, strong) NSString *top_controller;
@property (nonatomic, strong) NSString *page_views_stack_info;

@end