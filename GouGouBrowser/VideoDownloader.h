//
//  VideoDownloader.h
//  GouGouBrowser
//
//  Created by jia on 13-7-7.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoDownloadDelegate.h"
#import "RegexKitLite.h"
#import <sqlite3.h>
#import "AppDelegate.h"
#import "extentions.h"
#import "ASIHTTPRequest.h"

#define databaseFilename @"database.sqlite3"

@interface VideoDownloader : NSOperation {
    NSString *videoTitle ;
    NSString *site ;
    NSString *m3u8Url ;
    NSString *m3u8Md5 ;
    NSString *playUrl ;
    NSMutableArray *tsUrlArray ;
    
    NSOperationQueue *queue ;
    NSOperationQueue *addQueue ;
    NSInteger *downloadingCount ;
    NSDate *lastBytesReceived;
    id <VideoDownloadDelegate> delegate;
}

@property (nonatomic,retain) id delegate;
@property (nonatomic,retain) NSString *videoTitle ;
@property (nonatomic,retain) NSString *site ;
@property (nonatomic,retain) NSString *m3u8Url ;
@property (nonatomic,retain) NSString *playUrl ;
@property (nonatomic,retain) NSString *m3u8Md5 ;
@property (nonatomic,retain) NSMutableArray *tsUrlArray ;

@property (nonatomic,retain) NSOperationQueue *queue ;

@property (nonatomic) NSInteger *downloadingCount ;
@property (nonatomic,retain) NSDate *lastBytesReceived;

+(sqlite3 *)database;

+(void)setDatabase:(sqlite3 *)_db;

+(NSString *)dataFilePath;

+(NSString *) downloadWhilePlayFilePath ;


+(NSNumber *) getDownloadNums ;

+(void) setDownloadNums:(NSNumber *) _nums ;

+(NSString *) downloadNumsFilePath ;

+(void) initDatabase ;

+ (int)getVideoFileSize:(NSString *) m3u8UrlMd5;

+ (int)getVideoFileCompletedSize:(NSString *) m3u8UrlMd5 ;

+(NSString *)videoDocFilePathforSite:(NSString *)site m3u8UrlMd5:(NSString * )m3u8UrlMd5 ;

+(NSDictionary *) getAllDownloadVideos:(NSNumber *) isCompleted;

+(int) getAllDownloadVideosCount:(BOOL) isCompleted;

+(void) removeVideoBySite:(NSString *)site withM3u8Url : (NSString *) m3u8Url;

+(void) setCompletedBySite:(NSString *)site withM3u8Url : (NSString *) m3u8Url;

-(void)reportFinishedadd;
-(id)initWithM3u8Md5:(NSString *) m3u8UrlMd5;

-(BOOL) isDownloaded ;

-(void) fetchTsFiles ;

-(void) fetchTsFilesFromM3u8Contents:(NSString *)response;

-(int) getUnCompleteTsCount;

-(int) getCompleteTsCount;

-(BOOL) isCompleted ;

+(id) createSubDocumentDirectory:(NSString *) basePath relativePath:(NSString *) rPath;

-(void) download:(NSString *) m3u8Md5 ;

-(void) cancelDownload ;

+(BOOL) didWatchedVideo:(NSString *) m3u8Md5;

+(NSString *) wifi3GConfigFilePath;

- (BOOL)isPureInt:(NSString*)string;

+(NSArray *)getVideoWithM3u8Url:(NSString *)m3u8Url site:(NSString *)site;

+(void) addHistory: (NSString *) url withTitle:(NSString *)title;
+(void) delHistory: (BOOL) isClear withUrlMD5 : (NSString *) urlMD5;
+(NSMutableArray *) selectHistory: (NSInteger) type withLimit : (NSInteger) limit;

@end
