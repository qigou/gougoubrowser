//
//  LocalViewController.h
//  GouGouBrowser
//
//  Created by jia on 13-7-9.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "VideoDownloader.h"
#import "LocalSubViewController.h"
#import "UIFolderTableView.h"
#import "VideoPlayerVieoController.h"

@interface LocalViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>{
    UIBarButtonItem *closeButtonItem;
    UIBarButtonItem *editButtonItem;
    UINavigationItem *navigationItem;
    
    NSMutableArray *downloadedVideos ;
}

@property (retain, nonatomic) IBOutlet UIFolderTableView *tableView;
@property (retain, nonatomic) IBOutlet UINavigationBar *navigation_bar;
@property (retain, nonatomic) IBOutlet UITableViewCell *localVideoCell;

@property (nonatomic,strong) NSMutableArray *downloadedVideos ;

@property (nonatomic,retain)NSIndexPath *selectIndex;

- (IBAction)openSubView:(id)sender;

@end
