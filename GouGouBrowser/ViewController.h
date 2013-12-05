//
//  ViewController.h
//  GouGouBrowser
//
//  Created by jia on 13-6-20.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadViewController.h"
#import "JSNotifier.h"
#import "JMWhenTapped.h"
#import "VideoDownloadDelegate.h"
#import "AppDelegate.h"
#import "HTTPServer.h"
#import "HomeViewController.h"
#import "VideoPlayerVieoController.h"
#import "BookMarkViewController.h"
#import "HistoryViewController.h"
#import "KxMenu.h"
#import "AddressTextField.h"
#import "MKNumberBadgeView.h"
#import "ASIHTTPRequest.h"
#import "MBProgressHUD.h"

@interface ViewController : UIViewController<UIWebViewDelegate,UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource,VideoDownloadDelegate>{
    ASIHTTPRequest *httpRequest;
}

//@property (retain, nonatomic) UIImageView *imageView;
@property (retain, nonatomic) IBOutlet UIImageView *imageView;
- (IBAction)showPop:(id)sender;
@property (retain, nonatomic) IBOutlet UIButton *showPopBtn;
@property (retain, nonatomic) UIButton *searchBtn;
@property (retain, nonatomic) AddressTextField *text_url;
@property (retain, nonatomic) UIWebView *webView;
@property (retain, nonatomic) UIButton *stopReloadButton;
@property (retain, nonatomic) UIButton *cancelBtn;
@property (retain, nonatomic) IBOutlet UIToolbar *toolBar;

//@property (nonatomic, retain) UIToolbar *toolBar;
@property (nonatomic, retain) UIBarButtonItem *btn_go;
@property (nonatomic, retain) UIBarButtonItem *btn_back;
@property (nonatomic, retain) UIBarButtonItem *btn_home;
@property (nonatomic, retain) UIBarButtonItem *btn_setting;
@property (nonatomic, retain) UIBarButtonItem *btn_bookmark;
@property (nonatomic, retain) UIBarButtonItem *btn_files;

@property (retain, nonatomic) UITableView *table;
@property (strong, nonatomic) NSArray *listData;

@property (retain, nonatomic)JSNotifier *notify;

@property (retain, nonatomic) MKNumberBadgeView *bgView;

@property (nonatomic,retain) NSTimer *refreshTimer ;

@property (nonatomic, retain) UIAlertView *loadingAlert;

@property (nonatomic, retain) MBProgressHUD *hud;

@end
