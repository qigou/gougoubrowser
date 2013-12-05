//
//  HistoryViewController.h
//  GouGouBrowser
//
//  Created by jia on 13-7-14.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Cell1.h"
#import "Cell2.h"
#import "VideoDownloader.h"

@interface HistoryViewController : UIViewController<UIActionSheetDelegate>

@property (retain, nonatomic) IBOutlet UINavigationBar *navigation_bar;
@property (retain, nonatomic) UINavigationItem *navigationItem;

@property (nonatomic,retain)NSIndexPath *selectIndex;
@property (retain, nonatomic) IBOutlet UITableView *table;

@end
