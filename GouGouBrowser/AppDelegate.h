//
//  AppDelegate.h
//  GouGouBrowser
//
//  Created by jia on 13-6-20.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoDownloader.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>{
    float systemVersion ;
    UIBackgroundTaskIdentifier taskID;
    NSTimer *backgroundAudioTimer ;
    NSOperationQueue *addQueue ;
    float downloading_kbPerSec;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@property (nonatomic) float systemVersion ;

@property (retain, nonatomic) NSMutableDictionary *downloadVideos ;

@property (nonatomic,retain) NSOperationQueue *addQueue ;

@property (nonatomic) float downloading_kbPerSec ;

- (void) cancelDownload:(NSString *)m3u8Md5;

- (void) downloadDone ;

- (void) increaseLocalBadageValue;

- (void) cleanLocalBadageValue;

- (void) addDownload:(NSDictionary *)downloadInfo delegate:(id <VideoDownloadDelegate>)delegate;

- (void) addDownloadWithM3u8Md5:(NSString *)m3u8Md5;

- (void) addBookMark:(NSMutableDictionary *) dic;

- (void) editBookMark:(NSMutableDictionary *) dic withIndex : (NSInteger) index;

- (void) delBookMark:(NSInteger) index withUrlMD5 : (NSString *) urlMD5;

- (BOOL) bookMarkExist:(NSString *) urlMD5;

- (NSArray *) quickLinkList;

- (BOOL) quickLinkExist : (NSString *) urlMD5;

- (void) delQuickLink: (NSInteger) index withUrlMD5 : (NSString *) urlMD5;

- (void) addQuickLink:(NSMutableDictionary *) dic;

- (void) editQuickLink:(NSMutableDictionary *) dic withIndex : (NSInteger) index;

@property (nonatomic) UIBackgroundTaskIdentifier taskID;
@property (nonatomic,retain) NSTimer *backgroundAudioTimer ;

+ (NSDate *) getCurrentDate;

@end
