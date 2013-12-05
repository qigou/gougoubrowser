//
//  AddBookMarkController.h
//  GouGouBrowser
//
//  Created by jia on 13-7-13.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "MyTextField.h"
#import "AppDelegate.h"
#import "extentions.h"

@interface AddBookMarkController : UIViewController<UITextFieldDelegate>

@property (retain, nonatomic) IBOutlet UINavigationBar *navigation_bar;

@property (retain, nonatomic) UINavigationItem *navigationItem;
@property (retain, nonatomic) UIImageView *imgView;
@property (retain, nonatomic) MyTextField *input_title;
@property (retain, nonatomic) MyTextField *input_url;
@property (retain, nonatomic) UIBarButtonItem *saveButtonItem;

@property (retain, nonatomic) NSString *navigationTitle;
@property (retain, nonatomic) NSMutableDictionary *editDic;

- (id) initWithIsAdd:(BOOL) isAdd withDic : (NSMutableDictionary *) dic withIndex : (NSInteger) index;

@end
