//
//  AppDelegate.m
//  GouGouBrowser
//
//  Created by jia on 13-6-20.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

@implementation AppDelegate

@synthesize systemVersion, downloadVideos, taskID, backgroundAudioTimer, addQueue, downloading_kbPerSec;

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString* _systemVersion = [[UIDevice currentDevice] systemVersion];
    systemVersion = [_systemVersion floatValue];
    
    self.addQueue = [[NSOperationQueue alloc] init];
    [self.addQueue setMaxConcurrentOperationCount:5];
    
    self.downloadVideos = [NSMutableDictionary dictionary];
    
    //创建目录
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManage = [NSFileManager defaultManager];
    NSString *myDirectory = [documentsDirectory stringByAppendingPathComponent:@"quick_link"];
    [fileManage createDirectoryAtPath:myDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    
    //通过本地plist文件在document下创建文件
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"quickLink.plist"];
    if(![fileManage fileExistsAtPath:filePath]) //如果不存在
    {
        NSLog(@"quickLink.plist is not exist");
        
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"quickLink" ofType:@"plist"];
        NSMutableArray *data_arr = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
        
        //输入写入
        [data_arr writeToFile:filePath atomically:YES];
        
        [data_arr release];
    }
    //bookmark plist
    NSString *bookmarkFilePath = [documentsDirectory stringByAppendingPathComponent:@"bookmark.plist"];
    if(![fileManage fileExistsAtPath:bookmarkFilePath]) {
        [fileManage createFileAtPath:bookmarkFilePath contents:nil attributes:nil];
    }
     
    //初始化sqllite
    [VideoDownloader initDatabase];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.viewController = [[[ViewController alloc] initWithNibName:@"ViewController" bundle:nil] autorelease];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void) addDownloadWithM3u8Md5:(NSString *)m3u8Md5{
    NSLog(@"add download %@" , m3u8Md5);
    VideoDownloader *downloader = (VideoDownloader *)[downloadVideos objectForKey:m3u8Md5] ;
    if (downloader != nil) {
        [self cancelDownload:m3u8Md5];
    }
    //[VideoDownloader initDatabase];
    VideoDownloader *videoDown = [[[VideoDownloader alloc] initWithM3u8Md5:m3u8Md5] autorelease] ;
    [videoDown download:m3u8Md5] ;
    
    //[self.downloadVideos setObject:videoDown forKey:m3u8Md5] ;
}

- (void) cancelDownload:(NSString *)m3u8Md5 {
    NSLog(@"downloads %@" , self.downloadVideos);
    VideoDownloader *downloader = (VideoDownloader *)[self.downloadVideos objectForKey:m3u8Md5] ;
    if ( downloader != nil) {
        [downloader cancelDownload] ;
        [downloadVideos removeObjectForKey:m3u8Md5] ;
        //[downloader release];
    }
}

- (void) addDownload:(NSDictionary *)downloadInfo delegate:(id <VideoDownloadDelegate>)delegate
{
    
    //NSString *m3u8Md5 = [[downloadInfo objectForKey:@"m3u8Url"] md5];
    
    NSString *m3u8Md5 = [[NSString stringWithFormat:@"%@_%@" ,
                          [downloadInfo objectForKey:@"site"],
                          [downloadInfo objectForKey:@"m3u8Url"]] md5];
    
    VideoDownloader *downloader = (VideoDownloader *)[downloadVideos objectForKey:m3u8Md5] ;
    if (downloader != nil) {
        [self cancelDownload:m3u8Md5];
    }
    
    //[VideoDownloader initDatabase];
    
    VideoDownloader *videoDown = [[VideoDownloader alloc] init] ;

    videoDown.videoTitle = [downloadInfo objectForKey:@"videoTitle"];
    videoDown.site = [downloadInfo objectForKey:@"site"];
    videoDown.m3u8Url = [downloadInfo objectForKey:@"m3u8Url"];
    videoDown.playUrl = [downloadInfo objectForKey:@"playUrl"];
    videoDown.m3u8Md5 = m3u8Md5 ;
    videoDown.delegate = delegate;
    
    [self.addQueue addOperation:videoDown];
    
    [videoDown release];
    
    NSLog(@"step 222222222 addOperation");
    
    //[self.downloadVideos setObject:videoDown forKey:m3u8Md5] ;
    //NSLog(@"downloads %@" , self.downloadVideos);
    
}

- (void) downloadDone {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"videoDownloadDone" object:self userInfo:nil];
}

- (void) increaseLocalBadageValue
{
//    self.LocalBadageValue = [NSNumber numberWithInt:([self.LocalBadageValue intValue] + 1)] ;
//    if ([self.LocalBadageValue intValue] > 0) {
//        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:[self.LocalBadageValue stringValue]];
//    }
//    else {
//        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
//    }
}

//新增书签
- (void) addBookMark:(NSMutableDictionary *) dic {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"bookmark.plist"];
    NSMutableArray *data_arr = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    
    if([data_arr count] == 0){
        data_arr = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    [data_arr addObject:dic];
    [data_arr writeToFile:plistPath atomically:YES];    
    [data_arr release];
}

- (void) editBookMark:(NSMutableDictionary *) dic withIndex : (NSInteger) index {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"bookmark.plist"];
    NSMutableArray *data_arr = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    
    if([data_arr count] == 0){
        data_arr = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    [data_arr replaceObjectAtIndex:index withObject:dic];
    [data_arr writeToFile:plistPath atomically:YES];
    [data_arr release];
}

- (void) delBookMark:(NSInteger) index withUrlMD5:(NSString *) urlMD5 {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"bookmark.plist"];
    NSMutableArray *data_arr = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    
    if([data_arr count] == 0){
        data_arr = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    if(index == -1) {
        for(int i=0;i<[data_arr count];i++){
            NSMutableDictionary *quickLink = [data_arr objectAtIndex:i];
            NSString *objUrlMD5 = [quickLink objectForKey:@"urlMD5"];
            if([urlMD5 isEqualToString:objUrlMD5]){
                index = i;
                break;
            }
        }
    }
    [data_arr removeObjectAtIndex:index];
    [data_arr writeToFile:plistPath atomically:YES];
    [data_arr release];
}

- (BOOL) bookMarkExist:(NSString *) urlMD5 {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"bookmark.plist"];
    NSMutableArray *data_arr = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    
    BOOL flag = NO;
    if(data_arr && [data_arr count] != 0) {
        for(int i=0;i<[data_arr count];i++){
            NSMutableDictionary *quickLink = [data_arr objectAtIndex:i];
            NSString *objUrlMD5 = [quickLink objectForKey:@"urlMD5"];
            if([urlMD5 isEqualToString:objUrlMD5]){
                flag = YES;
                break;
            }
        }
    }
    return flag;
}

- (NSArray *) quickLinkList {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"quickLink.plist"];
    
    NSMutableArray *data_arr = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    
    return data_arr;
}

- (BOOL) quickLinkExist : (NSString *) urlMD5 {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"quickLink.plist"];
    NSMutableArray *data_arr = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    
    BOOL flag = NO;
    if(data_arr && [data_arr count] != 0) {
        for(int i=0;i<[data_arr count];i++){
            NSMutableDictionary *quickLink = [data_arr objectAtIndex:i];
            NSString *objUrlMD5 = [quickLink objectForKey:@"urlMD5"];
            if([urlMD5 isEqualToString:objUrlMD5]){
                flag = YES;
                break;
            }
        }
    }
    return flag;
}

- (void) delQuickLink: (NSInteger) index withUrlMD5 : (NSString *) urlMD5 {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"quickLink.plist"];
    NSMutableArray *data_arr = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    
    if([data_arr count] == 0){
        data_arr = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    if(index == -1) {
        for(int i=0;i<[data_arr count];i++){
            NSMutableDictionary *quickLink = [data_arr objectAtIndex:i];
            NSString *objUrlMD5 = [quickLink objectForKey:@"urlMD5"];
            if([urlMD5 isEqualToString:objUrlMD5]){
                index = i;
                break;
            }
        }
    }
    [data_arr removeObjectAtIndex:index];
    [data_arr writeToFile:plistPath atomically:YES];
    [data_arr release];
}

- (void) addQuickLink:(NSMutableDictionary *) dic {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"quickLink.plist"];
    NSMutableArray *data_arr = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    
    if([data_arr count] == 0){
        data_arr = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    [data_arr addObject:dic];
    [data_arr writeToFile:plistPath atomically:YES];
    [data_arr release];
}

- (void) editQuickLink:(NSMutableDictionary *) dic withIndex : (NSInteger) index {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"quickLink.plist"];
    NSMutableArray *data_arr = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    
    if([data_arr count] == 0){
        data_arr = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    [data_arr replaceObjectAtIndex:index withObject:dic];
    [data_arr writeToFile:plistPath atomically:YES];
    [data_arr release];
}

+ (NSDate *) getCurrentDate {
    NSDate *date = [NSDate date];
    //获取当前时区
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    //以秒为单位返回当前应用程序与世界标准时间（格林威尼时间）的时差
    NSInteger interval = [zone secondsFromGMTForDate: date];
    
    return [date dateByAddingTimeInterval: interval];
}

- (void) cleanLocalBadageValue
{
//    LocalBadageValue = [NSNumber numberWithInt:0] ;
//    [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
