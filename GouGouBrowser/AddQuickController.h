//
//  AddQuickController.h
//  GouGouBrowser
//
//  Created by jia on 13-6-23.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyTextField.h"
#import "AddQuickDelegate.h"

@interface AddQuickController : UIViewController<UITextFieldDelegate>{
    UIBarButtonItem *closeButtonItem;
    UIBarButtonItem *saveButtonItem;
    UINavigationItem *navigationItem;
    NSObject<AddQuickDelegate> *addQuickDelegate;
}

@property (retain, nonatomic) UIImageView *imgView;
@property (retain, nonatomic) MyTextField *input_title;
@property (retain, nonatomic) MyTextField *input_url;

@property (retain, nonatomic) IBOutlet UINavigationBar *navigationbar;

@property (retain, nonatomic) NSObject<AddQuickDelegate> *addQuickDelegate;

@end
