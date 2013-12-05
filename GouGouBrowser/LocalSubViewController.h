//
//  LocalSubViewController.h
//  GouGouBrowser
//
//  Created by jia on 13-7-10.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocalSubViewController : UIViewController

@property (strong, nonatomic) UIViewController *con;
@property (retain, nonatomic) IBOutlet UIButton *playBtn;
@property (retain, nonatomic) IBOutlet UIButton *delBtn;

@end