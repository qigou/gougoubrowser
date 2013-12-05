//
//  VideoDownloader.m
//  GouGouBrowser
//
//  Created by jia on 13-7-7.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "VideoDownloader.h"

static sqlite3 *database;

@implementation VideoDownloader

@synthesize videoTitle, site, m3u8Url, m3u8Md5, playUrl, tsUrlArray, queue, downloadingCount, lastBytesReceived, delegate;

-(void) dealloc {
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    if (myapp.systemVersion >= 5.0) {
        [videoTitle release];
        [site release];
        [m3u8Url release];
        [playUrl release];
        [queue release] ;
    }
    //[self cancelDownload];
    //[super dealloc];
}

+(sqlite3 *)database {
    return database ;
}
+(void)setDatabase:(sqlite3 *)_db {
    database = _db ;
}


+ (NSString *)dataFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
														 NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:databaseFilename];
}

+(NSString *) downloadWhilePlayFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
														 NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"DownloadWhilePlay.plist"];
}

+(NSString *) wifi3GConfigFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
														 NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"Wifi3GConfig.plist"];
}

+(NSString *) downloadNumsFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
														 NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"Downloadnums.plist"];
}

+(NSNumber *) getDownloadNums
{
    NSArray *_numtmp = [[NSArray alloc] initWithContentsOfFile:[VideoDownloader downloadNumsFilePath]] ;
    if ([_numtmp count] > 0 ) {
        NSNumber *_returnNum = [_numtmp objectAtIndex:0];
        [_numtmp release] ;
        return _returnNum;
    }
    else {
        NSNumber *_returnNum = [NSNumber numberWithInt:5];
        [_numtmp release] ;
        return _returnNum;
    }
}

+(void) setDownloadNums:(NSNumber *) _nums ;
{
    
    NSArray *_tmp = [[NSArray alloc] initWithObjects:_nums, nil];
    NSString *_path = [VideoDownloader downloadNumsFilePath] ;
    [_tmp writeToFile:_path atomically:YES] ;
    [_tmp release] ;
    NSLog(@"%@" , [NSString stringWithFormat:@"settingDownloadNums%d" , [_nums integerValue]]);
}

+(NSString *)videoDocFilePathforSite:(NSString *)site m3u8UrlMd5:(NSString * )m3u8UrlMd5 {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // 设置目录结构
    // http server 主目录
    /*
     NSString *httpRootDirectory = [self createSubDocumentDirectory:documentsDirectory relativePath:@"http"] ;
     // 设置站点目录
     NSString *siteRootDirectory = [self createSubDocumentDirectory:httpRootDirectory relativePath:site] ;
     // 设置videiid目录
     NSString *siteVidRootDirectory = [self createSubDocumentDirectory:siteRootDirectory relativePath:videoid] ;
     // 设置子集目录
     NSString *sitenumberRootDirectory = [self createSubDocumentDirectory:siteVidRootDirectory relativePath:number] ;
     */
    
    NSString *videoDirectory = [NSString stringWithFormat:@"%@/http/%@",documentsDirectory,m3u8UrlMd5] ;
    
    return videoDirectory;
}

+(void) initDatabase {
    
    // 连接数据库
    sqlite3 *_database ;
    NSLog(@"asdf %d" , sqlite3_threadsafe());
    if (sqlite3_open_v2([[VideoDownloader dataFilePath] UTF8String], &_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_AUTOPROXY | SQLITE_OPEN_FULLMUTEX, NULL) != SQLITE_OK){
        //if (sqlite3_open([[VideoDownloader dataFilePath] UTF8String], &_database) != SQLITE_OK) {
        sqlite3_close([VideoDownloader database]);
        NSAssert(0, @"Failed to open database");
    }
    [VideoDownloader setDatabase:_database] ;
    
    // 创建数据表
    char *errorMsg;
    NSString *createVideoSQL = @"CREATE TABLE IF NOT EXISTS VIDEOS (m3u8UrlMd5 CHAR(32) PRIMARY KEY,videoTitle CHAR(255),site VARCHAR(255),m3u8Url TEXT,playUrl TEXT,lastUpdateTime CHAR(255),status INTEGER);";
    if (sqlite3_exec ([VideoDownloader database], [createVideoSQL UTF8String],
                      NULL, NULL, &errorMsg) != SQLITE_OK) {
        //sqlite3_close([VideoDownloader database]);
        NSAssert1(0, @"Error creating table: %s", errorMsg);
    }
    
    NSString *createTsSQL = @"CREATE TABLE IF NOT EXISTS TSFILES (tsUrlMd5 CHAR(32) PRIMARY KEY,m3u8UrlMd5 CHAR(32),tsUrl TEXT,tsFileSize INTEGER,startedTime CHAR(255),finishedTime CHAR(255),status INTEGER);";
    if (sqlite3_exec ([VideoDownloader database], [createTsSQL UTF8String],
                      NULL, NULL, &errorMsg) != SQLITE_OK) {
        //sqlite3_close([VideoDownloader database]);
        NSAssert1(0, @"Error creating table: %s", errorMsg);
    }
    
    //浏览纪录
    NSString *createHistorySQL = @"CREATE TABLE IF NOT EXISTS LINKHISTORY (urlMD5 CHAR(32) PRIMARY KEY,title CHAR(255),url VARCHAR(255),lastUpdateTime CHAR(255));";
    if (sqlite3_exec ([VideoDownloader database], [createHistorySQL UTF8String],
                      NULL, NULL, &errorMsg) != SQLITE_OK) {
        NSAssert1(0, @"Error creating table: %s", errorMsg);
    }

}

+ (int)getVideoFileSize:(NSString *) m3u8UrlMd5 {
    
    // 未完成缓存的ts文件格式
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(1) AS count FROM TSFILES WHERE m3u8UrlMd5='%@' AND status=0",m3u8UrlMd5]  ;
    sqlite3_stmt *statement;
    int uncompleteCount = 0 ;
    if (sqlite3_prepare_v2([VideoDownloader database], [query UTF8String],-1, &statement, nil) == SQLITE_OK) {
        if(sqlite3_step(statement) == SQLITE_ROW) {
            uncompleteCount = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
    }
    //NSLog(@"ddd , %d" , uncompleteCount) ;
    
    // 已完成缓存的ts文件个数和总大小
    NSString *query2 = [NSString stringWithFormat:@"SELECT tsFileSize FROM TSFILES WHERE m3u8UrlMd5='%@' AND status=1",m3u8UrlMd5]  ;
    sqlite3_stmt *statement2;
    int tsFileCompletedSize = 0 ;
    int tsFileCompletedCount = 0 ;
    if (sqlite3_prepare_v2([VideoDownloader database], [query2 UTF8String],
                           -1, &statement2, nil) == SQLITE_OK) {
        while (sqlite3_step(statement2) == SQLITE_ROW) {
            
            tsFileCompletedSize = tsFileCompletedSize +sqlite3_column_int(statement2, 0);
            tsFileCompletedCount = tsFileCompletedCount + 1 ;
            
        }
        sqlite3_finalize(statement2);
    }
    // ts文件大小的平均值
    if (tsFileCompletedCount > 0){
        return uncompleteCount * (tsFileCompletedSize / tsFileCompletedCount)  + tsFileCompletedSize ;
    }
    else {
        return 0 ;
    }
    
}

+ (int)getVideoFileCompletedSize:(NSString *) m3u8UrlMd5 {
    NSString *query = [NSString stringWithFormat:@"SELECT tsFileSize FROM TSFILES WHERE m3u8UrlMd5='%@' AND status=1",m3u8UrlMd5]  ;
    sqlite3_stmt *statement;
    int tsFileCompletedSize = 0 ;
    if (sqlite3_prepare_v2([VideoDownloader database], [query UTF8String],
                           -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            
            tsFileCompletedSize = tsFileCompletedSize +sqlite3_column_int(statement, 0);
            
        }
        sqlite3_finalize(statement);
    }
    return tsFileCompletedSize ;
}

+ (BOOL) didWatchedVideo:(NSString *) m3u8Md5{
    BOOL watched = NO ;
    NSString *_query = [NSString stringWithFormat:@"SELECT * FROM VIDEOS WHERE m3u8UrlMd5='%@'",m3u8Md5] ;
    //NSLog(@"%@" , _query) ;
    sqlite3_stmt *_statement;
    if (sqlite3_prepare_v2([VideoDownloader database], [_query UTF8String],-1, &_statement, nil) == SQLITE_OK) {
        if(sqlite3_step(_statement) == SQLITE_ROW) {
            watched = YES;
        }
        sqlite3_finalize(_statement);
    }
    
    return watched ;
}

+(int) getAllDownloadVideosCount:(BOOL) isCompleted
{
    NSString *query ;
    int count = 0 ;
    if (isCompleted) {
        query = @"SELECT COUNT(1) AS count FROM VIDEOS WHERE status=1";
    }
    else {
        query = @"SELECT COUNT(1) AS count FROM VIDEOS WHERE status=0";
    }
    
    sqlite3_stmt *_statement;
    if (sqlite3_prepare_v2([VideoDownloader database], [query UTF8String],-1, &_statement, nil) == SQLITE_OK) {
        if(sqlite3_step(_statement) == SQLITE_ROW) {
            count = (int)sqlite3_column_int(_statement, 0);
        }
        sqlite3_finalize(_statement);
    }
    return count ;
}

+(NSArray *)getVideoWithM3u8Url:(NSString *)m3u8Url site:(NSString *)site {
    NSMutableArray *_array = [NSMutableArray arrayWithCapacity:100];
    NSString *query ;
    
    NSString *m3u8Md5 = [[NSString stringWithFormat:@"%@_%@",site, m3u8Url] md5];
    
//    NSLog(@"%@",m3u8Md5);
    
    query = [NSString stringWithFormat:@"SELECT m3u8UrlMd5,site,m3u8Url,playUrl,lastUpdateTime,status,videoTitle FROM VIDEOS WHERE m3u8UrlMd5='%@' or site='%@'" , m3u8Md5, site];
    sqlite3_stmt *_statement2 ;
    if (sqlite3_prepare_v2([VideoDownloader database], [query UTF8String],
                           -1, &_statement2, nil) == SQLITE_OK) {
        while (sqlite3_step(_statement2) == SQLITE_ROW) {
            
            char *__m3u8UrlMd5 = (char *)sqlite3_column_text(_statement2, 0);
            char *__site = (char *)sqlite3_column_text(_statement2, 1);
            char *__m3u8Url = (char *)sqlite3_column_text(_statement2, 2);
            char *__playUrl = (char *)sqlite3_column_text(_statement2, 3);
            char *__status = (char *)sqlite3_column_text(_statement2, 5);
            
            char *__videoTitle = (char *)sqlite3_column_text(_statement2, 6);
            
            NSString *_m3u8UrlMd5 = [[NSString alloc]
                                     initWithUTF8String:__m3u8UrlMd5];
            NSString *_site = [[NSString alloc]
                               initWithUTF8String:__site];
            NSString *_m3u8Url = [[NSString alloc]
                                  initWithUTF8String:__m3u8Url];
            NSString *_playUrl = [[NSString alloc]
                                  initWithUTF8String:__playUrl];
            
            NSString *_videoTitle = [[NSString alloc]
                                     initWithUTF8String:__videoTitle];
            
            NSString *_status = [[NSString alloc]
                                     initWithUTF8String:__status];
            [_array addObject:[NSMutableDictionary
                               dictionaryWithObjectsAndKeys:
                               _videoTitle , @"videoTitle",
                               _site , @"site",
                               _m3u8Url , @"m3u8Url",
                               _playUrl , @"playUrl",
                               _status, @"status",
                               nil]] ;
            [_m3u8UrlMd5 release];
            [_videoTitle release] ;
            [_site release];
            [_m3u8Url release];
            [_playUrl release];
        }
        sqlite3_finalize(_statement2);
    }
    
    return _array;
}

+(NSDictionary *) getAllDownloadVideos:(NSNumber *) isCompleted{
    // 查询数据库，是否有曾经缓存过
    NSMutableArray *_array = [NSMutableArray arrayWithCapacity:100];
    NSString *query ;
    if ([isCompleted boolValue]) {
        //query = @"SELECT m3u8UrlMd5,videoid,number,numberTitle,site,m3u8Url,playUrl,lastUpdateTime,status,videoTitle FROM VIDEOS WHERE status=1 ORDER BY videoid DESC,number ASC";
        query = @"SELECT m3u8UrlMd5,site,m3u8Url,playUrl,lastUpdateTime,status,videoTitle FROM VIDEOS WHERE status=1 ORDER BY lastUpdateTime DESC";
    }
    else {
        //query = @"SELECT m3u8UrlMd5,videoid,number,numberTitle,site,m3u8Url,playUrl,lastUpdateTime,status,videoTitle FROM VIDEOS WHERE status=0 ORDER BY videoid DESC,number ASC";
        query = @"SELECT m3u8UrlMd5,site,m3u8Url,playUrl,lastUpdateTime,status,videoTitle FROM VIDEOS WHERE status=0 ORDER BY lastUpdateTime DESC";
    }
    //NSString *query = @"SELECT m3u8UrlMd5,videoid,number,numberTitle,site,m3u8Url,playUrl,lastUpdateTime,status,videoTitle FROM VIDEOS ORDER BY videoid DESC,number ASC";
    //sqlite3_stmt *_statement2;
    sqlite3_stmt *_statement2 ;
    int videoCount = 0;
    int videoFileSize = 0 ;
    if (sqlite3_prepare_v2([VideoDownloader database], [query UTF8String],
                           -1, &_statement2, nil) == SQLITE_OK) {
        while (sqlite3_step(_statement2) == SQLITE_ROW) {
            
            char *__m3u8UrlMd5 = (char *)sqlite3_column_text(_statement2, 0);
            char *__site = (char *)sqlite3_column_text(_statement2, 1);
            char *__m3u8Url = (char *)sqlite3_column_text(_statement2, 2);
            char *__playUrl = (char *)sqlite3_column_text(_statement2, 3);
            char *__lastUpdateTime = (char *)sqlite3_column_text(_statement2, 4);
            int __status = sqlite3_column_int(_statement2, 5);
            char *__videoTitle = (char *)sqlite3_column_text(_statement2, 6);
            
            NSString *_m3u8UrlMd5 = [[NSString alloc]
                                     initWithUTF8String:__m3u8UrlMd5];
            NSString *_site = [[NSString alloc]
                               initWithUTF8String:__site];
            NSString *_m3u8Url = [[NSString alloc]
                                  initWithUTF8String:__m3u8Url];
            NSString *_playUrl = [[NSString alloc]
                                  initWithUTF8String:__playUrl];
            NSString *_lastUpdateTime = [[NSString alloc]
                                         initWithUTF8String:__lastUpdateTime];
            NSString *_videoTitle = [[NSString alloc]
                                     initWithUTF8String:__videoTitle];
            
            NSNumber *_status = [NSNumber numberWithInt:__status];
            
            int __filesize = [VideoDownloader getVideoFileSize:_m3u8UrlMd5] ;
            int __completedsize = [VideoDownloader getVideoFileCompletedSize:_m3u8UrlMd5] ;
            //NSLog(@"%d", __filesize);
            NSNumber *_filesize = [NSNumber numberWithInt:__filesize] ;
            NSNumber *_completedsize = [NSNumber numberWithInt:__completedsize] ;
            
            videoCount ++;
            videoFileSize = videoFileSize + (__completedsize / 1024) ;
            
            //NSLog(@"")
            
            [_array addObject:[NSMutableDictionary
                               dictionaryWithObjectsAndKeys:
                               _m3u8UrlMd5 , @"_m3u8UrlMd5",
                               _videoTitle , @"videoTitle",
                               _site , @"site",
                               _m3u8Url , @"m3u8Url",
                               _playUrl , @"playUrl",
                               _lastUpdateTime , @"lastUpdateTime",
                               _status , @"status",
                               _filesize , @"_filesize",
                               _completedsize,@"_completedsize",
                               [NSNumber numberWithBool:NO],@"isDownloading",
                               @"",@"downloadingSpeed",
                               nil]] ;
            [_m3u8UrlMd5 release];
            [_videoTitle release] ;
            [_site release];
            [_m3u8Url release];
            [_playUrl release];
            [_lastUpdateTime release];
        }
        sqlite3_finalize(_statement2);
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            _array,                                 @"videos",
            [NSNumber numberWithInt:videoCount],    @"videocount",
            [NSNumber numberWithInt:videoFileSize], @"videofilesize",
            nil];
}
/*
 videoDown.videoid = [downloadInfo objectForKey:@"videoid"];
 videoDown.videoTitle = [downloadInfo objectForKey:@"videoTitle"];
 videoDown.number = [downloadInfo objectForKey:@"number"];
 videoDown.numberTitle = [downloadInfo objectForKey:@"numberTitle"];
 videoDown.site = [downloadInfo objectForKey:@"site"];
 videoDown.m3u8Url = [downloadInfo objectForKey:@"m3u8Url"];
 videoDown.playUrl = [downloadInfo objectForKey:@"playUrl"];
 
 char *update = "INSERT OR REPLACE INTO VIDEOS (m3u8UrlMd5, videoid,videoTitle,number,numberTitle,site,m3u8Url,playUrl,lastUpdateTime,status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
 */

+(void) setCompletedBySite:(NSString *)site withM3u8Url : (NSString *) m3u8Url{
    NSString *_m3u8Md5 = [[NSString stringWithFormat:@"%@_%@",site, m3u8Url] md5];
    
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    [myapp cancelDownload:_m3u8Md5];
    // 删除数据库记录
    char *errorMsg;
    NSString *deleteTsSQL = [NSString stringWithFormat:@"DELETE FROM TSFILES WHERE m3u8UrlMd5='%@' AND status=0",_m3u8Md5] ;
    NSLog(@"eee%@" , deleteTsSQL);
    
    if (sqlite3_exec ([VideoDownloader database], [deleteTsSQL UTF8String],
                      NULL, NULL, &errorMsg) != SQLITE_OK) {
        //sqlite3_close([VideoDownloader database]);
        NSAssert1(0, @"Error delete: %s", errorMsg);
    }
    
    // 添加结束标记
    NSString *sitenumberRootDirectory = [VideoDownloader videoDocFilePathforSite:site m3u8UrlMd5:_m3u8Md5];
    NSString *m3u8FileString = [NSString stringWithContentsOfFile:[[sitenumberRootDirectory stringByAppendingString:@"/"] stringByAppendingString:@"playlist.m3u8"] encoding:NSUTF8StringEncoding error:NULL] ;
    
    NSString *_replacedM3u8String = [m3u8FileString stringByReplacingOccurrencesOfString:@"#CUSTONER END LIST" withString:@"#EXT-X-ENDLIST" ] ;
    [_replacedM3u8String writeToFile:[[sitenumberRootDirectory stringByAppendingString:@"/"] stringByAppendingString:@"playlist.m3u8"] atomically:YES encoding:NSUTF8StringEncoding error:NULL] ;
    
    
    
    // 更新videos表的状态位
    char *errorMsg3;
    NSDate *date = [NSDate date];
    //获取当前时区
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    //以秒为单位返回当前应用程序与世界标准时间（格林威尼时间）的时差
    NSInteger interval = [zone secondsFromGMTForDate: date];
    //补充时差后为当前时间
    NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
    NSString *updateVideosSQL = [NSString stringWithFormat:@"UPDATE VIDEOS SET status=1,lastUpdateTime='%@' WHERE m3u8UrlMd5='%@'",[localeDate description] , _m3u8Md5] ;
    if (sqlite3_exec ([VideoDownloader database], [updateVideosSQL UTF8String],
                      NULL, NULL, &errorMsg3) != SQLITE_OK) {
        //sqlite3_close([VideoDownloader database]);
        NSAssert1(0, @"Error creating table: %s", errorMsg3);
    }
    
    [myapp downloadDone];
}


+(void) removeVideoBySite:(NSString *)site withM3u8Url : (NSString *) m3u8Url{
    // 停止缓存
    NSString *_m3u8Md5 = [[NSString stringWithFormat:@"%@_%@",site, m3u8Url] md5];
    
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    [myapp cancelDownload:_m3u8Md5];
    
    // 删除集数目录
    NSString *sitenumberRootDirectory = [VideoDownloader videoDocFilePathforSite:site m3u8UrlMd5:_m3u8Md5];
    
    NSLog(@"path is %@" , sitenumberRootDirectory) ;
    NSFileManager *_filemanager = [NSFileManager defaultManager] ;
    [_filemanager removeItemAtPath:sitenumberRootDirectory error:nil] ;
    
    
    // 删除数据库记录
    char *errorMsg;
    NSString *deleteTsSQL = [NSString stringWithFormat:@"DELETE FROM TSFILES WHERE m3u8UrlMd5='%@'",_m3u8Md5] ;
    NSLog(@"eee%@" , deleteTsSQL);
    
    if (sqlite3_exec ([VideoDownloader database], [deleteTsSQL UTF8String],
                      NULL, NULL, &errorMsg) != SQLITE_OK) {
        //sqlite3_close([VideoDownloader database]);
        NSAssert1(0, @"Error delete: %s", errorMsg);
    }
    
    NSString *deleteVideoSQL = [NSString stringWithFormat:@"DELETE FROM VIDEOS WHERE m3u8UrlMd5='%@'",_m3u8Md5] ;
    if (sqlite3_exec ([VideoDownloader database], [deleteVideoSQL UTF8String],
                      NULL, NULL, &errorMsg) != SQLITE_OK) {
        //sqlite3_close([VideoDownloader database]);
        NSAssert1(0, @"Error delete: %s", errorMsg);
    }
}

/*
 多线程启动下载，不阻塞
 */
-(void) main
{
    [self download:self.m3u8Md5];
    [self performSelectorOnMainThread:@selector(reportFinishedadd) withObject:nil waitUntilDone:YES];
    
    NSLog(@"step 333333333 fun main");
}


-(void)reportFinishedadd
{
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    if ([self.tsUrlArray count] > 0) {
        [myapp increaseLocalBadageValue];
    }
    if ([self.tsUrlArray count] > 0 && self.delegate && [self.delegate respondsToSelector:@selector(addDownloadFinished)]) {
        [self.delegate performSelector:@selector(addDownloadFinished) withObject:self];
        [self.delegate release];
    }
    else if ([self.tsUrlArray count] <= 0 && self.delegate && [self.delegate respondsToSelector:@selector(addDownloadError:)]) {
        NSNumber *Error ;
        if ([self isCompleted]) {
            Error = [NSNumber numberWithInteger:1] ; // 下载已完成
        }
        else {
            Error = [NSNumber numberWithInteger:2] ; // 资源失效
        }
        
        [self.delegate performSelector:@selector(addDownloadError:) withObject:Error];
        [self.delegate release];
    }
}
-(id)initWithM3u8Md5:(NSString *) m3u8UrlMd5{
    if (self = [super init]) {
        NSString *_query = [NSString stringWithFormat:@"SELECT videoTitle,site,m3u8Url,playUrl FROM VIDEOS WHERE m3u8UrlMd5='%@'",m3u8UrlMd5] ;
        sqlite3_stmt *_statement;
        if (sqlite3_prepare_v2(database, [_query UTF8String],-1, &_statement, nil) == SQLITE_OK) {
            if(sqlite3_step(_statement) == SQLITE_ROW) {
                char *v_videotitle = (char *)sqlite3_column_text(_statement, 0);
                char *v_site = (char *)sqlite3_column_text(_statement, 1);
                char *v_m3u8url = (char *)sqlite3_column_text(_statement, 2);
                char *v_playurl = (char *)sqlite3_column_text(_statement, 3);
                
                NSString *v__videotitle = [[NSString alloc]
                                           initWithUTF8String:v_videotitle];
                NSString *v__site = [[NSString alloc]
                                     initWithUTF8String:v_site];
                NSString *v__m3u8url = [[NSString alloc]
                                        initWithUTF8String:v_m3u8url];
                NSString *v__playurl = [[NSString alloc]
                                        initWithUTF8String:v_playurl];
                
                self.videoTitle = v__videotitle;
                self.site = v__site;
                self.m3u8Url = v__m3u8url;
                self.playUrl = v__playurl;
                
                [v__videotitle release];
                [v__site release] ;
                [v__m3u8url release] ;
                [v__playurl release] ;
            }
            sqlite3_finalize(_statement);
        }
    }
    return self;
}


-(BOOL) isDownloaded {
    return YES ;
}

-(int) getUnCompleteTsCount
{
    //    NSString *_m3u8Md5 = [site md5];
    NSString *_m3u8Md5 = [[NSString stringWithFormat:@"%@_%@",site, m3u8Url] md5];
    
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) AS count FROM TSFILES WHERE m3u8UrlMd5='%@' AND status=0", _m3u8Md5] ;
    sqlite3_stmt *statement;
    int count = 0 ;
    if (sqlite3_prepare_v2([VideoDownloader database], [query UTF8String],
						   -1, &statement, nil) == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
			count = sqlite3_column_int(statement, 0);
			
		}
		sqlite3_finalize(statement);
    }
//    NSLog(@"left ts files %d" , count);
    return count ;
}

-(int) getCompleteTsCount
{
    //    NSString *_m3u8Md5 = [site md5];
    NSString *_m3u8Md5 = [[NSString stringWithFormat:@"%@_%@",site, m3u8Url] md5];
    
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) AS count FROM TSFILES WHERE m3u8UrlMd5='%@' AND status=1",_m3u8Md5] ;
    sqlite3_stmt *statement;
    int count = 0 ;
    if (sqlite3_prepare_v2([VideoDownloader database], [query UTF8String],
						   -1, &statement, nil) == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
			count = sqlite3_column_int(statement, 0);
			
		}
		sqlite3_finalize(statement);
    }
    NSLog(@"completed ts files %d" , count);
    return count ;
}

-(BOOL) isCompleted
{
    return ([self getUnCompleteTsCount] == 0 && [self getCompleteTsCount] > 0);
}

-(void) fetchTsFilesFromM3u8Contents:(NSString *)response
{
    NSString *_m3u8Md5 = [[NSString stringWithFormat:@"%@_%@",site, m3u8Url] md5];
    
    // 分析m3u8里包含m3u8的协议
    /*
     #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=491520
     http://121.12.101.67:80/12051222D617CCE860BD013BF1E86A9AD0775586/playlist.m3u8
     #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=491520
     http://113.17.170.134:80/12051222D617CCE860BD013BF1E86A9AD0775586/playlist.m3u8
     */
    NSString *regexString2 = @"#EXT-X-STREAM-INF:PROGRAM-ID=\\d+,BANDWIDTH=(\\d+)\\r\\n([^\\n\\r]+)";
    NSArray *matchArray2 = NULL;
    matchArray2 = [response arrayOfCaptureComponentsMatchedByRegex:regexString2];
    NSLog(@"ddddddddd%@" , matchArray2) ;
    
    NSString *_newM3u8Url = @"" ;
    if ([matchArray2 count] > 0) {
        
        int bandwidth = 0 ;
        
        for(NSArray *_m3u8Config in matchArray2) {
            if ([[_m3u8Config objectAtIndex:1] intValue] > bandwidth) {
                bandwidth = [[_m3u8Config objectAtIndex:1] intValue] ;
                _newM3u8Url = [_m3u8Config objectAtIndex:2] ;
            }
        }
        
        NSLog(@"new m3u8 url is %@" , _newM3u8Url) ;
        
        response = [NSString stringWithContentsOfURL:[NSURL URLWithString:_newM3u8Url]
                                            encoding:NSUTF8StringEncoding error:nil];
        //NSLog(@"ts files :%@" , response);
        
    }
    NSString *parseM3u8Url = [_newM3u8Url isEqualToString:@""] ? m3u8Url : _newM3u8Url ;
    
    
    // 重写m3u8，替换URL为md5(url)
    //NSString *searchString = @"This is neat.";
    NSString *replaceRegexString = @"(#EXTINF:[^\\n]+)\\n([^\\n\\r]+)";
    NSString *replacedM3u8String = NULL;
    replacedM3u8String = [[[response stringByReplacingOccurrencesOfRegex:replaceRegexString
                                                              usingBlock:
                            ^NSString *(NSInteger captureCount,
                                        NSString * const capturedStrings[captureCount],
                                        const NSRange capturedRanges[captureCount],
                                        volatile BOOL * const stop) {
                                
                                NSString *_tsUrl ;
                                
                                if ([capturedStrings[2] hasPrefix:@"http"]) {
                                    _tsUrl = capturedStrings[2] ;
                                }
                                else if ([capturedStrings[2] hasPrefix:@"/"]) {
                                    //NSLog(@"%@" , [NSURL URLWithString:m3u8Url]);
                                    //NSLog(@"%@" , [[NSURL URLWithString:m3u8Url] path]);
                                    
                                    _tsUrl = [NSString stringWithFormat:@"%@://%@:%@%@" , [[NSURL URLWithString:parseM3u8Url] scheme], [[NSURL URLWithString:parseM3u8Url] host],[[[NSURL URLWithString:parseM3u8Url] port] stringValue],capturedStrings[2]];
                                    //_tsUrl = [[m3u8Url stringByReplacingOccurrencesOfString:[[NSURL URLWithString:m3u8Url] path] withString:@""] stringByAppendingString:capturedStrings[2]];
                                    
                                }
                                else {
                                    _tsUrl = [[[[NSURL URLWithString:parseM3u8Url] URLByDeletingLastPathComponent] absoluteString] stringByAppendingString:capturedStrings[2]];
                                }
                                return([NSString stringWithFormat:@"#CUSTOMER%@%@\n#%@",
                                        [_tsUrl md5], capturedStrings[1] , [_tsUrl md5]]);
                            }] stringByReplacingOccurrencesOfString:@"#EXT-X-ENDLIST" withString:@"#CUSTONER END LIST"]
                          stringByReplacingOccurrencesOfString:@"#EXT-X-PLAYLIST-TYPE:VOD" withString:@""];
    
    // 取到用户目录
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    
    // 设置目录结构
    // http server 主目录
    NSString *httpRootDirectory = [VideoDownloader createSubDocumentDirectory:documentsDirectory relativePath:@"http"] ;
    // 设置video目录
    NSString *videoDirectory = [VideoDownloader createSubDocumentDirectory:httpRootDirectory relativePath:_m3u8Md5] ;
    
    
    // 写入M3U8文件到本地文件
    NSString *savePath = [NSString stringWithFormat:@"%@.m3u8",@"playlist"];
    NSString *filepath = [[videoDirectory stringByAppendingString:@"/"] stringByAppendingString:savePath];
    [replacedM3u8String writeToFile:filepath atomically:YES encoding:NSUTF8StringEncoding error:NULL] ;
    
    NSString *regexString = @"(#EXTINF:[^\\n]+)\\n([^\\n\\r]+)";
    NSArray *matchArray = NULL;
    matchArray = [response arrayOfCaptureComponentsMatchedByRegex:regexString];
    
    if ([matchArray count] == 0) {
        //        [self reportSubMovieError] ;
        return ;
    }
    
    // 写入m3u8Url的记录到数据库
    char *errorMsg = NULL;
    char *update = "INSERT OR REPLACE INTO VIDEOS (m3u8UrlMd5, videoTitle,site,m3u8Url,playUrl,lastUpdateTime,status) VALUES (?, ?, ?, ?, ?, ?, ?);";
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2([VideoDownloader database], update, -1, &stmt, nil) == SQLITE_OK) {
        
        //        NSString *_m3u8Md5 = [NSString stringWithFormat:@"%@_%@_%@" , videoid,
        //                              site,number];
        sqlite3_bind_text(stmt, 1, [_m3u8Md5 UTF8String], -1 , NULL);

        sqlite3_bind_text(stmt, 2, [videoTitle UTF8String],-1,NULL);
        
        sqlite3_bind_text(stmt, 3, [site UTF8String],-1,NULL);
        sqlite3_bind_text(stmt, 4, [m3u8Url UTF8String],-1,NULL);
        sqlite3_bind_text(stmt, 5, [playUrl UTF8String],-1,NULL);
        NSDate *date = [NSDate date];
        //获取当前时区
        NSTimeZone *zone = [NSTimeZone systemTimeZone];
        //以秒为单位返回当前应用程序与世界标准时间（格林威尼时间）的时差
        NSInteger interval = [zone secondsFromGMTForDate: date];
        //补充时差后为当前时间
        NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
        sqlite3_bind_text(stmt, 6, [[localeDate description] UTF8String],-1,NULL);
        sqlite3_bind_int(stmt, 7, 0);
    }
    if (sqlite3_step(stmt) != SQLITE_DONE)
        NSAssert1(0, @"Error updating table: %s", errorMsg);
    sqlite3_finalize(stmt);
    
    //NSLog(@"data %@" , matchArray);
    // 构造tsUrlArray数组
    //NSMutableString *insertSQL = [NSMutableString stringWithString:@""];
    //int tsInsertCount = 0 ;
    
    // sqllite prepare
    char *errorMsg2;
    char *query = "INSERT OR REPLACE INTO TSFILES (tsUrlMd5, m3u8UrlMd5,tsUrl,tsFileSize,startedTime,finishedTime,status) VALUES (?, ?, ?, ?, ?, ?, ?);";
    sqlite3_stmt *stmt2;
    sqlite3_prepare_v2([VideoDownloader database], query, -1, &stmt2, nil);
    sqlite3_exec([VideoDownloader database], "BEGIN TRANSACTION", NULL, NULL, &errorMsg2);
    
    for(NSArray *tsURLConfig in matchArray) {
        NSString *tsUrlString ;
        if ([[tsURLConfig objectAtIndex:2] hasPrefix:@"http"]) {
            tsUrlString = [tsURLConfig objectAtIndex:2] ;
        }
        else if ([[tsURLConfig objectAtIndex:2] hasPrefix:@"/"]) {
            
            
            tsUrlString = [NSString stringWithFormat:@"%@://%@:%@%@" , [[NSURL URLWithString:parseM3u8Url] scheme], [[NSURL URLWithString:parseM3u8Url] host],[[[NSURL URLWithString:parseM3u8Url] port] stringValue],[tsURLConfig objectAtIndex:2]];
        }
        else {
            tsUrlString = [[[[NSURL URLWithString:parseM3u8Url] URLByDeletingLastPathComponent] absoluteString] stringByAppendingString:[tsURLConfig objectAtIndex:2]];
        }
        
        
        //NSString *tsUrlString = [tsURLConfig objectAtIndex:2] ;
        NSString *tsExtInfo = [tsURLConfig objectAtIndex:1] ;
        NSString *extInfoRegex = @"#EXTINF:(\\d+)" ;
        NSArray *extInfoRegexRelt = NULL ;
        extInfoRegexRelt = [tsExtInfo captureComponentsMatchedByRegex:extInfoRegex];
        //NSLog(@"extinf %@" , extInfoRegexRelt);
        
        if ([extInfoRegexRelt count] == 2 && [[extInfoRegexRelt objectAtIndex:1] intValue] <= 0) {
            NSLog(@"duration is 0,pass!");
            continue ;
        }
        NSNumber *tsStatus = [NSNumber numberWithInt:0] ;
        [tsUrlArray addObject:[NSDictionary
                               dictionaryWithObjectsAndKeys:tsUrlString,@"url",
                               tsStatus,@"status",
                               nil]] ;
        // 构造插入sql
        /*
         NSString *_tmpString = [NSString stringWithFormat:@"INSERT OR REPLACE INTO TSFILES (tsUrlMd5, m3u8UrlMd5,tsUrl,tsFileSize,startedTime,finishedTime,status) VALUES ('%@', '%@', '%@', %d, '%@', '%@', %d);\n" , [tsUrlString md5],[_m3u8Md5 md5],tsUrlString,0,[[NSDate date] description],@"",0] ;
         insertSQL = [NSMutableString stringWithString:[insertSQL stringByAppendingString:_tmpString]];
         
         
         
         
         tsInsertCount ++ ;
         */
        
        /*
         char *errorMsg;
         char *TSupdate = "INSERT OR REPLACE INTO TSFILES (tsUrlMd5, m3u8UrlMd5,tsUrl,tsFileSize,startedTime,finishedTime,status) VALUES (?, ?, ?, ?, ?, ?, ?);";
         sqlite3_stmt *stmt;
         NSString *_m3u8Md5 = [NSString stringWithFormat:@"%@_%@_%@" , videoid,
         site,number];
         */
        //if (sqlite3_prepare_v2([VideoDownloader database], TSupdate, -1, &stmt, nil) == SQLITE_OK) {
        
        sqlite3_bind_text(stmt2, 1, [[tsUrlString md5] UTF8String], -1 , SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt2, 2, [_m3u8Md5 UTF8String],-1,SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt2, 3, [tsUrlString UTF8String],-1,SQLITE_TRANSIENT);
        sqlite3_bind_int(stmt2, 4, 0);
        
        NSDate *date = [NSDate date];
        //获取当前时区
        NSTimeZone *zone = [NSTimeZone systemTimeZone];
        //以秒为单位返回当前应用程序与世界标准时间（格林威尼时间）的时差
        NSInteger interval = [zone secondsFromGMTForDate: date];
        //补充时差后为当前时间
        NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
        sqlite3_bind_text(stmt2, 5, [[localeDate description] UTF8String],-1,SQLITE_TRANSIENT);
        
        sqlite3_bind_text(stmt2, 6, [@"" UTF8String],-1,SQLITE_TRANSIENT);
        sqlite3_bind_int(stmt2, 7, 0);
        sqlite3_step(stmt2);
        sqlite3_clear_bindings(stmt2);
        sqlite3_reset(stmt2);
        //}
        /*
         if (sqlite3_step(stmt) != SQLITE_DONE)
         NSAssert1(0, @"Error updating table: %s", errorMsg);
         sqlite3_finalize(stmt);
         */
    }
    sqlite3_exec([VideoDownloader database], "END TRANSACTION", NULL, NULL, &errorMsg2);
    
    sqlite3_finalize(stmt2);
}

-(void) fetchTsFiles {
    // 查询数据库，是否有曾经缓存过
    tsUrlArray = [NSMutableArray arrayWithCapacity:100];
    //    NSString *_m3u8Md5 = [site md5];
    NSString *_m3u8Md5 = [[NSString stringWithFormat:@"%@_%@",site, m3u8Url] md5];
    NSString *query = [NSString stringWithFormat:@"SELECT tsUrl,status FROM TSFILES WHERE m3u8UrlMd5='%@'",_m3u8Md5] ;
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2([VideoDownloader database], [query UTF8String],
						   -1, &statement, nil) == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
			int __status = sqlite3_column_int(statement, 1);
			char *__tsUrl = (char *)sqlite3_column_text(statement, 0);
			
			NSString *_tsUrlString = [[NSString alloc]
                                      initWithUTF8String:__tsUrl];
			NSNumber *_tsUrlStatus = [NSNumber numberWithInt:__status];
			
            [tsUrlArray addObject:[NSDictionary
                                   dictionaryWithObjectsAndKeys:_tsUrlString,@"url",
                                   _tsUrlStatus,@"status",
                                   nil]] ;
			[_tsUrlString release];
		}
		sqlite3_finalize(statement);
    }
    
    if ([tsUrlArray count] == 0) { // 数据库没有对应的m3u8里面的ts文件的缓存记录，缓存m3u8文件并且分析出ts文件地址
        NSURL *url = [NSURL URLWithString:m3u8Url];
        
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        request.timeOutSeconds = 10 ;
        [request startSynchronous];
        
        if (request.error == nil) {
            NSString *response = [request responseString];
            [self fetchTsFilesFromM3u8Contents:response];
        }
    }
}


+(id) createSubDocumentDirectory:(NSString *) basePath relativePath:(NSString *) rPath
{
    NSFileManager *_filemamger = [NSFileManager defaultManager] ;
    BOOL isDir ;
    NSString *targetDirectory = [[basePath stringByAppendingString:@"/"] stringByAppendingString:rPath] ;
    if (!([_filemamger fileExistsAtPath:targetDirectory isDirectory:&isDir] && isDir)){
        [_filemamger createDirectoryAtPath:targetDirectory withIntermediateDirectories:YES attributes:nil error:nil] ;
    }
    return targetDirectory ;
    
}

-(void) download:(NSString *) _m3u8Md5
{
    //[NSThread sleepForTimeInterval:5];
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    
    //    if(![myapp canPlayDownloadByNetworkConfigure]) {
    //        return ;
    //    }
    
    if([self isCompleted]) {
        return ;
    }
    
    NSLog(@"downloading") ;
    
    
    [self fetchTsFiles] ;
    
    if ([tsUrlArray count] <= 0) {
        return ;
    }
    
    if ([[VideoDownloader getDownloadNums] intValue] != -1 && [[myapp.downloadVideos allKeys] count] >= [[VideoDownloader getDownloadNums] intValue]) {
        // 不再启动缓存任务
        return ;
    }
    
    [ASIHTTPRequest setDefaultUserAgentString:@"Mozilla/5.0 (iPhone; CPU iPhone OS 5_0_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Mobile/9A405"];
    
    
    // 循环取到的m3u8文件里的ts文件的url
    
    
    if ([tsUrlArray count] && ![self queue]) {
        NSOperationQueue *downloadOperationQueue = [[NSOperationQueue alloc] init] ;
        [downloadOperationQueue autorelease] ;
        [downloadOperationQueue setMaxConcurrentOperationCount:1] ;
        //[self setQueue:downloadOperationQueue] ;
        self.queue = downloadOperationQueue ;
    }
    downloadingCount = 0 ;
    NSLog(@"downloading queue");
    for(NSDictionary *tsURLConfig in tsUrlArray) {
        //NSLog(@"url:%@" , [tsURLConfig objectAtIndex:2]) ;
        NSString *tsUrlString = [tsURLConfig objectForKey:@"url"] ;
        NSNumber *tsUrlStatus = [tsURLConfig objectForKey:@"status"];
        
        // 只有当状态为0的时候，记录ts文件到数据库,并且加入缓存队列
        if ([tsUrlStatus isEqualToNumber:[NSNumber numberWithInt:0]]) {
            // 将ts文件加入缓存队列
            NSURL *url = [NSURL URLWithString:tsUrlString];
            
            //NSLog(@"url:%@,status:%@" , url,tsUrlStatus) ;
            
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
            [request setAllowCompressedResponse:NO];
            request.shouldWaitToInflateCompressedResponses = NO ;
            [request addRequestHeader:@"User-Agent" value:@"AppleCoreMedia/1.0.0.9A405 (iPhone; U; CPU OS 5_0_1 like Mac OS X; zh_cn)"];
            [request addRequestHeader:@"Accept" value:@"*/*"];
            [request addRequestHeader:@"Accept-Encoding" value:@"identity"];
            //[request addRequestHeader:@"X-Playback-Session-Id" value:@"BE2A45C7-BEF1-4172-A181-D79D4936458F"];
            //[request setUseCookiePersistence:NO];
            
            [request setDelegate:self];
            [request setDownloadProgressDelegate:self];
            [request setDidFinishSelector: @selector (requestDone:)];
            [request setDidFailSelector: @selector (requestWentWrong:)];
            [[self queue] addOperation:request]; //queue is an NSOperationQueue
            //self.downloading = YES ;
            downloadingCount ++ ;
        }
    }
    [myapp.downloadVideos setObject:self forKey:_m3u8Md5] ;
}
/*
 -(void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes
 {
 AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
 if (!self.lastBytesReceived)
 self.lastBytesReceived = [NSDate date];
 
 NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.lastBytesReceived];
 if (interval > 0 && bytes > 0) {
 float KB = (bytes / 1024);
 
 float kbPerSec =  KB * (1.0/interval); //KB * (1 second / interval (less than one second))
 
 NSLog(@"%llu bytes received in %f seconds @ %0.01fKB/s",bytes,interval, kbPerSec);
 myapp.downloading_kbPerSec = kbPerSec ;
 self.lastBytesReceived = [NSDate date];
 
 }
 
 
 }
 */
- ( void )requestDone:(ASIHTTPRequest *)request
{
    
//    NSLog(@"header %d" , request.responseStatusCode);
    downloadingCount -- ;
    NSData *responseData = [request responseData];
    NSUInteger contentLength = [responseData length] ;
    //    NSString *_m3u8Md5 = [[NSString stringWithFormat:@"%@_%@_%@" , self.videoid,
    //                           self.site,self.number] md5];
    NSString *_m3u8Md5 = [[NSString stringWithFormat:@"%@_%@",self.site, self.m3u8Url] md5];
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    
    
    if (contentLength < 1024) { // 取到的文件小于1K
        //return ;
    }
    
    if (request.responseStatusCode != 200) {
        NSLog(@"request data is not validated!");
        return ;
    }
    
    
    NSString *sitenumberRootDirectory = [VideoDownloader videoDocFilePathforSite:site m3u8UrlMd5:_m3u8Md5];
    
//    NSLog(@"LENGTH IS %d" , contentLength) ;
    
    NSString *tsUrlMd5String = [[[request originalURL] absoluteString] md5] ;
    NSString *savePath = [NSString stringWithFormat:@"%@.ts",tsUrlMd5String];
    NSString *filepath = [[sitenumberRootDirectory stringByAppendingString:@"/"] stringByAppendingString:savePath];
    [responseData writeToFile:filepath atomically:YES] ;
    
//    NSLog(@"write to file:%@" , filepath) ;
    
    // update m3u8 file the ts url
    NSString *m3u8FileString = [NSString stringWithContentsOfFile:[[sitenumberRootDirectory stringByAppendingString:@"/"] stringByAppendingString:@"playlist.m3u8"] encoding:NSUTF8StringEncoding error:NULL] ;
    NSString *urlmd5tring = [[[request originalURL] absoluteString] md5] ;
    
    NSString *tmpreplacedM3u8String = [m3u8FileString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"#CUSTOMER%@" ,urlmd5tring]                                                                             withString:@""] ;
    
    NSString *replacedM3u8String = [tmpreplacedM3u8String stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"#%@" ,urlmd5tring]                                                                                    withString:[NSString stringWithFormat:@"http://127.0.0.1:12345/%@/%@.ts",m3u8Md5, urlmd5tring]] ;
    
    //#CUSTOMER
    
    //NSMutableString *replacedM3u8String = _replacedM3u8String ;
    char *errorMsg;
    NSDate *date = [NSDate date];
    //获取当前时区
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    //以秒为单位返回当前应用程序与世界标准时间（格林威尼时间）的时差
    NSInteger interval = [zone secondsFromGMTForDate: date];
    //补充时差后为当前时间
    NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
    NSString *updateTsSQL = [NSString stringWithFormat:@"UPDATE TSFILES SET status=1,finishedTime='%@',tsFileSize=%d WHERE tsUrlMd5='%@'",[localeDate description] , contentLength , tsUrlMd5String] ;
    if (sqlite3_exec ([VideoDownloader database], [updateTsSQL UTF8String],
                      NULL, NULL, &errorMsg) != SQLITE_OK) {
        //sqlite3_close([VideoDownloader database]);
        NSAssert1(0, @"Error creating table: %s", errorMsg);
    }
    
    
    if ([self isCompleted]) {
        NSString *_replacedM3u8String = [replacedM3u8String stringByReplacingOccurrencesOfString:@"#CUSTONER END LIST" withString:@"#EXT-X-ENDLIST" ] ;
        [_replacedM3u8String writeToFile:[[sitenumberRootDirectory stringByAppendingString:@"/"] stringByAppendingString:@"playlist.m3u8"] atomically:YES encoding:NSUTF8StringEncoding error:NULL] ;
        
        
        
        // 更新videos表的状态位
        char *errorMsg3;
        NSDate *date = [NSDate date];
        //获取当前时区
        NSTimeZone *zone = [NSTimeZone systemTimeZone];
        //以秒为单位返回当前应用程序与世界标准时间（格林威尼时间）的时差
        NSInteger interval = [zone secondsFromGMTForDate: date];
        //补充时差后为当前时间
        NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
        NSString *updateVideosSQL = [NSString stringWithFormat:@"UPDATE VIDEOS SET status=1,lastUpdateTime='%@' WHERE m3u8UrlMd5='%@'",[localeDate description] , _m3u8Md5] ;
        if (sqlite3_exec ([VideoDownloader database], [updateVideosSQL UTF8String],
                          NULL, NULL, &errorMsg3) != SQLITE_OK) {
            //sqlite3_close([VideoDownloader database]);
            NSAssert1(0, @"Error creating table: %s", errorMsg3);
        }
//        if (myapp.taskID != UIBackgroundTaskInvalid) {
//            //[app endBackgroundTask:taskID];
//            NSString *showSubTitle;
//            if ([self isPureInt:self.numberTitle]) {
//                showSubTitle = [NSString stringWithFormat:@"第%@集" , self.numberTitle] ;
//            }
//            else {
//                showSubTitle = self.numberTitle;
//            }
//            
//            [myapp sendDownloadLocalNotificationWithMessage:[NSString stringWithFormat:@"%@ %@缓存完成！" , self.videoTitle,showSubTitle] type:@"done"];
//        }
        
        [myapp downloadDone];
        
        
    }
    else {
        [replacedM3u8String writeToFile:[[sitenumberRootDirectory stringByAppendingString:@"/"] stringByAppendingString:@"playlist.m3u8"] atomically:YES encoding:NSUTF8StringEncoding error:NULL] ;
    }
    
    if (!downloadingCount) {
        
        [myapp cancelDownload:_m3u8Md5];
        
        if ([myapp.downloadVideos count] == 0 && myapp.taskID != UIBackgroundTaskInvalid) {
            NSLog(@"end backtask");
            [myapp.backgroundAudioTimer invalidate];
            [[UIApplication sharedApplication] endBackgroundTask:myapp.taskID];
        }
    }
    
//    NSLog(@"done saved");
    
}
- (BOOL)isPureInt:(NSString*)string{
    
    NSScanner* scan = [NSScanner scannerWithString:string];
    
    int val;
    
    return[scan scanInt:&val] && [scan isAtEnd];
    
}
- ( void )requestWentWrong:(ASIHTTPRequest *)request
{
    //NSError *error = [request error];
    /*
     AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
     NSString *_m3u8Md5 = [[NSString stringWithFormat:@"%@_%@_%@" , self.videoid,
     self.site,self.number] md5];
     if (!downloadingCount) {
     
     [myapp cancelDownload:_m3u8Md5];
     
     if ([myapp.downloadVideos count] == 0 && myapp.taskID != UIBackgroundTaskInvalid) {
     NSLog(@"end backtask2");
     [[UIApplication sharedApplication] endBackgroundTask:myapp.taskID];
     }
     }
     */
}

-(void) cancelDownload {
    if(queue != nil) {
        [queue cancelAllOperations] ;
    }
    //[queue release];
}

+(void) addHistory: (NSString *) url withTitle:(NSString *)title{
    // 写入数据库
    char *errorMsg = NULL;
    char *update = "INSERT OR REPLACE INTO LINKHISTORY (urlMD5, title, url, lastUpdateTime) VALUES (?, ?, ?, ?);";
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2([VideoDownloader database], update, -1, &stmt, nil) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, [[url md5] UTF8String], -1 , NULL);
        sqlite3_bind_text(stmt, 2, [title UTF8String],-1,NULL);
        sqlite3_bind_text(stmt, 3, [url UTF8String],-1,NULL);
        NSDate *date = [NSDate date];
        //获取当前时区
        NSTimeZone *zone = [NSTimeZone systemTimeZone];
        //以秒为单位返回当前应用程序与世界标准时间（格林威尼时间）的时差
        NSInteger interval = [zone secondsFromGMTForDate: date];
        //补充时差后为当前时间
        NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
        sqlite3_bind_text(stmt, 4, [[localeDate description] UTF8String],-1,NULL);
    }
    if (sqlite3_step(stmt) != SQLITE_DONE)
        NSAssert1(0, @"Error updating table: %s", errorMsg);
    sqlite3_finalize(stmt);
}

+(void) delHistory: (BOOL) isClear withUrlMD5 : (NSString *) urlMD5{
    // 删除数据库记录
    char *errorMsg;
    NSString *deleteTsSQL = [NSString stringWithFormat:@"DELETE FROM LINKHISTORY"];
    if(!isClear){
        deleteTsSQL = [deleteTsSQL stringByAppendingFormat:@" where urlMD5='%@'",urlMD5];
    }
    NSLog(@"%@",deleteTsSQL);
    
    if (sqlite3_exec ([VideoDownloader database], [deleteTsSQL UTF8String],
                      NULL, NULL, &errorMsg) != SQLITE_OK) {
        NSAssert1(0, @"Error delete: %s", errorMsg);
    }
}

//查询历史纪录 tpye: 1-今天 2-昨天 3-更早
+(NSMutableArray *) selectHistory: (NSInteger) type withLimit : (NSInteger) limit{    
    NSMutableArray *_array = [NSMutableArray arrayWithCapacity:100];
    NSString *query = @"SELECT urlMD5,title,url,lastUpdateTime FROM LINKHISTORY WHERE 1=1";
    
    NSDate *date = [NSDate date];
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    [gregorian setTimeZone:gmt];
    NSDateComponents *components = [gregorian components: NSUIntegerMax fromDate: date];
    [components setHour: 0];
    [components setMinute:0];
    [components setSecond: 0];

    NSDate *newDate, *newDate2;

    switch (type) {
        case 1:
            newDate = [gregorian dateFromComponents: components];
            query = [query stringByAppendingFormat:@" and lastupdatetime > '%@'",[newDate description]];
            break;
        case 2:
            newDate = [gregorian dateFromComponents: components];
            [components setDay:[components day] - 1];
            newDate2 = [gregorian dateFromComponents:components];
            query = [query stringByAppendingFormat:@" and lastupdatetime < '%@'",[newDate description]];
            query = [query stringByAppendingFormat:@" and lastupdatetime > '%@'",[newDate2 description]];
            break;
        case 3:
            [components setDay:[components day] - 1];
            newDate2 = [gregorian dateFromComponents:components];
            query = [query stringByAppendingFormat:@" and lastupdatetime < '%@'",[newDate2 description]];
            break;
        default:
            break;
    }
    
    query = [query stringByAppendingString:@" order by lastupdatetime desc"];
    
    if(-1 != limit){
        query = [query stringByAppendingFormat:@" limit 0,%d",limit];
    }
    
    query = [query stringByAppendingString:@";"];
    
    NSLog(@"%@",query);
    
    sqlite3_stmt *_statement2 ;

    if (sqlite3_prepare_v2([VideoDownloader database], [query UTF8String],
                           -1, &_statement2, nil) == SQLITE_OK) {
        while (sqlite3_step(_statement2) == SQLITE_ROW) {            
            char *urlMD5 = (char *)sqlite3_column_text(_statement2, 0);
            char *title = (char *)sqlite3_column_text(_statement2, 1);
            char *url = (char *)sqlite3_column_text(_statement2, 2);
            char *lastUpdateTime = (char *)sqlite3_column_text(_statement2, 3);
            
            NSString *_urlMd5 = [[NSString alloc] initWithUTF8String:urlMD5];
            NSString *_title = [[NSString alloc] initWithUTF8String:title];
            NSString *_url = [[NSString alloc] initWithUTF8String:url];
            NSString *_lastUpdateTime = [[NSString alloc] initWithUTF8String:lastUpdateTime];
            
            [_array addObject:[NSMutableDictionary
                               dictionaryWithObjectsAndKeys:
                               _title , @"title",
                               _url , @"url",
                               _lastUpdateTime , @"lastUpdateTime",
                               _urlMd5 , @"urlMd5",
                               nil]] ;
            [_urlMd5 release];
            [_title release] ;
            [_url release];
            [_lastUpdateTime release];
        }
        sqlite3_finalize(_statement2);
    }
    
    return _array;
}

@end
