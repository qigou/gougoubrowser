//
//  BookMarkViewController.h
//  GouGouBrowser
//
//  Created by jia on 13-7-13.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "AddBookMarkController.h"

@interface BookMarkViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (retain, nonatomic) IBOutlet UINavigationBar *navigation_bar;
@property (retain, nonatomic) IBOutlet UITableView *table;

@property (retain, nonatomic) UINavigationItem *navigationItem;
@property (retain, nonatomic) IBOutlet UITableViewCell *bookmark_cell;
@property (retain, nonatomic) UIBarButtonItem *saveButtonItem;

@property (retain, nonatomic) NSMutableArray *data_arr;
@end
