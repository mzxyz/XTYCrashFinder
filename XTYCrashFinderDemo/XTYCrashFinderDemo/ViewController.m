//
//  ViewController.m
//  XTYCrashFinderDemo
//
//  Created by Michael on 16/8/26.
//  Copyright © 2016年 Michael. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self crashCaseOne];
}

- (void)crashCaseOne
{
    NSArray *testArray = @[@"a",@"b",@"c"];
    
    /** beyond array bounds */
    [testArray objectAtIndex:4];
}

@end
