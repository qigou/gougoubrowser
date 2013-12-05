//
//  DownloadViewController.h
//  GouGouBrowser
//
//  Created by jia on 13-7-6.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "LocalViewController.h"
#import "MKNumberBadgeView.h"

@interface DownloadViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>{
    UIBarButtonItem *closeButtonItem;
    UIBarButtonItem *doneButtonItem;
    UINavigationItem *navigationItem;
    NSMutableArray *downloadedVideos ;
    NSTimer *refreshTimer ;
    NSTimer *refreshTimerStatusbar ;
//    UITableView *downloadTableView ;
    NSNumber *CompleteSegSelected ;
    NSMutableDictionary *localDiscInfo;
}

@property (retain, nonatomic) IBOutlet UINavigationBar *navigationBar;

@property (retain, nonatomic) IBOutlet UITableViewCell *localCell;

@property (retain, nonatomic) IBOutlet UITableView *downloadTableView;

@property (retain, nonatomic) MKNumberBadgeView *bgView;

@property (nonatomic,strong) NSMutableArray *downloadedVideos ;
@property (nonatomic,retain) NSTimer *refreshTimer ;
@property (nonatomic,retain) NSTimer *refreshTimerStatusbar ;
@property (nonatomic,retain) NSNumber *CompleteSegSelected ;
@property (nonatomic,retain) NSMutableDictionary *localDiscInfo;

@end
