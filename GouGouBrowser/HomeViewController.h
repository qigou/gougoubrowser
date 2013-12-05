//
//  HomeViewController.h
//  GouGouBrowser
//
//  Created by jia on 13-6-20.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include "BJGridItem.h"
#import "AddQuickDelegate.h"
#import "extentions.h"
#import "AppDelegate.h"
#import "ASIHTTPRequest.h"

@interface HomeViewController : UIViewController<UIScrollViewDelegate,BJGridItemDelegate,UIGestureRecognizerDelegate, AddQuickDelegate,UIWebViewDelegate,ASIHTTPRequestDelegate>{
    NSMutableArray *gridItems;
    BJGridItem *addbutton;
    int page;
    float preX;
    BOOL isMoving;
    CGRect preFrame;
    BOOL isEditing;
    UITapGestureRecognizer *singletap;
    ASIHTTPRequest *httpRequest;
//    UIPageControl *pageControl;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollview;
@property (retain, nonatomic) IBOutlet UIPageControl *pageControl;

- (void)Addbutton : (NSString *) btn_title withBtnImg : (NSString *) imgName isUserAdded:(BOOL) isUserAdde;

@end
