//
//  DetailViewController.h
//  XTYCrashFinder
//
//  Created by Mr.Sunday on 16/8/3.
//  Copyright © 2016年 Sunday. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

