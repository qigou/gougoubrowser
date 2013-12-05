//
//  DownloadViewController.m
//  GouGouBrowser
//
//  Created by jia on 13-7-6.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#define CMovieTitle 1
#define CMovieFileSize 2
#define CMovieDownloadingProcessBar  3
#define CMovieDownloadingStatus  4
#define CMovieDownloadingPercent  5
#define CMoviePauseDownloadBtn  7
#define CMoviePlayBtn  8
#define CMovieDownloadSpeed  9
#define CMovieStatusImage 13

#import "DownloadViewController.h"

@interface DownloadViewController ()

@end

@implementation DownloadViewController

@synthesize downloadedVideos, refreshTimer, refreshTimerStatusbar, downloadTableView, CompleteSegSelected, localDiscInfo, localCell, bgView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    NSTimeInterval _timeInterval = 1.0 ;
    self.refreshTimerStatusbar = [NSTimer scheduledTimerWithTimeInterval:_timeInterval target:self selector:@selector(refreshStatusBarOrientation) userInfo:nil repeats:NO];
    [super viewWillAppear:animated];
}

-(void)refreshStatusBarOrientation
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
//    self.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height );
//    if(IS_IPHONE_5) {
//        self.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height );
//    }
    [self.refreshTimerStatusbar invalidate];
}

-(void)viewDidAppear:(BOOL)animated {
    //NSLog(@"view appeared,reload table data") ;
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    [myapp cleanLocalBadageValue];
//    if (self.loadingView.hidden) {
//        NSLog(@"hidden") ;
//        //[self.loadingView setNeedsDisplay];
//        [self.loadingView setHidden:NO] ;
//        [self.loadingView startAnimating] ;
//        
//    }
    
//    downloadTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _navigationBar.frame.size.height, downloadTableView.frame.size.width, downloadTableView.frame.size.height)];
//    downloadTableView.delegate = self;
//    downloadTableView.dataSource = self;

    
    // 设置定时器
    NSTimeInterval _timeInterval = 1.0 ;
    [self.refreshTimer invalidate];
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:_timeInterval target:self selector:@selector(refreshDownload) userInfo:nil repeats:YES];
    [self resetDownloadVideos] ;
    
    [self.downloadTableView reloadData] ;
    
    [super viewDidAppear:animated];
}

-(void) viewDidDisappear:(BOOL)animated {
    [self.refreshTimer invalidate] ;
    [super viewDidDisappear:animated];
    bgView.value = 0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    CompleteSegSelected = 0;
    
    navigationItem = [[UINavigationItem alloc] init];
    
    UIColor *color = [UIColor colorWithRed:73/255.0 green:78/255.0 blue:90/255.0 alpha:1.0];
    
    UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    titleView.text = @"下载管理";
    [titleView setBackgroundColor:[UIColor clearColor]];
    [titleView setFont:[UIFont systemFontOfSize: 16.0]];
    titleView.textAlignment = NSTextAlignmentCenter;
    [titleView setTextColor:color];
    navigationItem.titleView = titleView;
    [titleView release];
    
    UIFont *textfont = [UIFont systemFontOfSize:12.0];
    
    //按钮背景图拉伸
    UIImage *originalImage = [UIImage imageNamed:@"actionsheet_button_background_normal_night"];
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 2.5, 0, 2.5);
    UIImage *stretchableImage = [originalImage resizableImageWithCapInsets:insets];
    
    UIButton *btn_close = [[UIButton alloc] initWithFrame:CGRectMake(0,0,50,30)];
    [btn_close setTitle:@"关 闭" forState:UIControlStateNormal];
    [btn_close setBackgroundImage:stretchableImage forState:UIControlStateNormal];
    [[btn_close titleLabel] setFont:textfont];
    [[btn_close titleLabel] setTextColor:[UIColor whiteColor]];
    [btn_close addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    
    closeButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btn_close];
    
    navigationItem.leftBarButtonItem = closeButtonItem;
    [closeButtonItem release];
    
    UIButton *btn_done = [[UIButton alloc] initWithFrame:CGRectMake(0,0,50,30)];
    [btn_done setTitle:@"已下载" forState:UIControlStateNormal];
    [btn_done setBackgroundImage:stretchableImage forState:UIControlStateNormal];
    [[btn_done titleLabel] setFont:textfont];
    [[btn_done titleLabel] setTextColor:[UIColor whiteColor]];
    [btn_done addTarget:self action:@selector(goLocal:) forControlEvents:UIControlEventTouchUpInside];

    doneButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btn_done];
    [btn_done release];
    
    navigationItem.rightBarButtonItem = doneButtonItem;    
    [doneButtonItem release];
    
    _navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [_navigationBar setItems:[NSArray arrayWithObject:navigationItem]];
    
    //badge set
    CGRect rect = [[doneButtonItem customView] frame];
    bgView = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(rect.origin.x + 37, rect.origin.y - 6 + 20, 18, 18)];
    bgView.hideWhenZero = YES;
    bgView.value = 0;
    bgView.pad = 1;
    bgView.strokeWidth = 1;
    bgView.font = [UIFont boldSystemFontOfSize:12];
    bgView.shadow = NO;
    [[self view] addSubview:bgView];
    [bgView release];
    
    //下载
    self.downloadedVideos = [NSMutableArray array];
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    if([myapp systemVersion] < 5.0) {
        NSTimeInterval _timeInterval = 3.0 ;
        [self.refreshTimer invalidate];
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:_timeInterval target:self selector:@selector(refreshDownload) userInfo:nil repeats:YES];
        [self resetDownloadVideos] ;
        [self.downloadTableView reloadData] ;
    }
    
    //注册通知 下载完成回调
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(videoDownloadDone:)
               name:@"videoDownloadDone"
             object:nil];
}

- (void) videoDownloadDone :(NSNotification*)sender{
    int bgViewValue = bgView.value;
    bgView.value = ++bgViewValue;
    
    [self resetDownloadVideos];
    [self.downloadTableView reloadData];
}

-(void) refreshDownload {
//    NSLog(@"refresh timer going!");
    [self resetDownloadVideos] ;
//    [self updateLocalDiscIntoLabel];
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    NSInteger _index_count = 0 ;
    NSInteger _downloading_count = 0 ;
    for (NSDictionary *_tmp in self.downloadedVideos) {
        if ( [myapp.downloadVideos objectForKey:[_tmp objectForKey:@"_m3u8UrlMd5"]] != nil) { // 正在缓存中
            NSIndexPath *__indexpath=[NSIndexPath indexPathForRow:_index_count inSection:0];
            [self updateDownloadingStatus:[_tmp objectForKey:@"_m3u8UrlMd5"]
                                indexPath:__indexpath] ;
            _downloading_count ++ ;
        }
        _index_count ++ ;
    }
    if (_downloading_count == 0) {
        myapp.downloading_kbPerSec = 0.0 ;
    }
}

-(void) updateDownloadingStatus:(NSString *)m3u8UrlMd5 indexPath:(NSIndexPath *)indexPath  {
    // 获取已经缓存的文件大小
    int _filesize = [VideoDownloader getVideoFileSize:m3u8UrlMd5] ;
    int _completedsize = [VideoDownloader getVideoFileCompletedSize:m3u8UrlMd5] ;
    
    UITableViewCell *cell = [self.downloadTableView cellForRowAtIndexPath:indexPath];
    
    UILabel *MovieDownloadSize = (UILabel *)[cell viewWithTag:CMovieFileSize];
    
    NSString *completedfileSize = [self formartFileSize:_completedsize];
    NSString *fileSize = [self formartFileSize:_filesize];
    MovieDownloadSize.text = [NSString stringWithFormat:@"%@/%@",completedfileSize,fileSize] ;
    
    // downloading percent
    float completepercent =  ((float) _completedsize/_filesize)*100 ;
    UILabel *MovieDownloadingPercent = (UILabel *)[cell viewWithTag:CMovieDownloadingPercent];
    MovieDownloadingPercent.text = [NSString stringWithFormat:@"%.1f%%%",completepercent] ;
    
    // downloading processbar
    UIProgressView *MovieDownloadingBar = (UIProgressView *)[cell viewWithTag:CMovieDownloadingProcessBar];
    //[MovieDownloadingBar setProgress:((float) completedsize/filesize)] ;
    if([MovieDownloadingBar respondsToSelector:@selector(setProgress:animated:)]) {
        [MovieDownloadingBar setProgress:((float) _completedsize/_filesize) animated:YES];
    }
    else {
        [MovieDownloadingBar setProgress:((float) _completedsize/_filesize)];
    }
    
    NSInteger row = [indexPath row] ;
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    NSString *imageName = @"pause";
    NSString *labelText = @"已暂停";
    if ([myapp.downloadVideos objectForKey:m3u8UrlMd5] != nil) {
        imageName = @"downloading";
        labelText = @"缓存中";
    }
    
    // 更新状态
    UIImageView *_statusImageView = (UIImageView *)[cell viewWithTag:CMovieStatusImage];
    if (_filesize == _completedsize) {
        // 有视频缓存完成，刷新表视图
        [self.downloadTableView reloadData];
    }
    else{
        _statusImageView.image = [UIImage imageNamed:imageName];
    }
    
    // 更新缓存状态文字
    UILabel *MovieDownloadStatus = (UILabel *)[cell viewWithTag:CMovieDownloadingStatus];
    MovieDownloadStatus.text = labelText;
    
    [[downloadedVideos objectAtIndex:row] setObject:[NSNumber numberWithInt:_filesize] forKey:@"_filesize"] ;
    [[downloadedVideos objectAtIndex:row] setObject:[NSNumber numberWithInt:_completedsize] forKey:@"_completedsize"] ;
    
}

-(NSString *)formartFileSize:(int) fileSize {
    //NSLog(@"filesize:%d" , fileSize) ;
    if(fileSize < 1024) {
        return [NSString stringWithFormat:@"%.2fB" , (float)fileSize];
    }
    else if (fileSize/1024 < 1024) {
        return [NSString stringWithFormat:@"%.2fKB" , (float)fileSize/1024];
    }
    else if ((fileSize/1024)/1024 < 1024) {
        return [NSString stringWithFormat:@"%.2fMB" , (float)(fileSize/1024)/1024];
    }
    else {
        return [NSString stringWithFormat:@"%.2fGB" , (float)((fileSize/1024)/1024)/1024];
    }
}

-(void) resetDownloadVideos {
    NSDictionary *downloadInfo = [VideoDownloader getAllDownloadVideos:CompleteSegSelected] ;
    
    self.downloadedVideos = [downloadInfo objectForKey:@"videos"] ;
    
//    NSMutableDictionary *_dicTmp = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[downloadInfo objectForKey:@"videocount"],[downloadInfo objectForKey:@"videofilesize"], nil] forKeys:[NSArray arrayWithObjects:@"videocount",@"videofilesize", nil]];
//    self.localDiscInfo = _dicTmp ;
    //[localDiscInfo setObject:[downloadInfo objectForKey:@"videocount"] forKey:@"videocount"] ;
    //[localDiscInfo setObject:[downloadInfo objectForKey:@"videofilesize"] forKey:@"videofilesize"] ;
    
}

- (void)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) goLocal:(id)sender
{
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.type = kCATransitionReveal;
    animation.duration = 0.7;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    
    LocalViewController *local_crl = [[LocalViewController alloc] init];
//    [self presentViewController:local_crl animated:YES completion:nil];
    [self.view.window.layer addAnimation:animation forKey:nil];
    
//    [local_crl setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self presentViewController:local_crl animated:NO completion:nil];
}

- (BOOL)isPureInt:(NSString*)string{
    
    NSScanner* scan = [NSScanner scannerWithString:string];
    
    int val;
    
    return[scan scanInt:&val] && [scan isAtEnd];
    
}

#pragma mark - Table view data source
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [downloadedVideos count];
}

//新建某一行并返回
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"LocalListCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LocalListCell"
													 owner:self options:nil];
        if ([nib count] > 0) {
            cell = self.localCell;
        } else {
            NSLog(@"failed to load CustomCell nib file!");
        }        
    }
    
    NSInteger row = [indexPath row] ;
    
    // movietitle
    UILabel *MovieTitle = (UILabel *)[cell viewWithTag:CMovieTitle];
    MovieTitle.text = [[self.downloadedVideos objectAtIndex:row] objectForKey:@"videoTitle"];
    
    // file size
    int filesize = [[[self.downloadedVideos objectAtIndex:row] objectForKey:@"_filesize"] intValue];
    int completedsize = [[[self.downloadedVideos objectAtIndex:row] objectForKey:@"_completedsize"] intValue] ;
    UILabel *MovieDownloadSize = (UILabel *)[cell viewWithTag:CMovieFileSize];
    
    NSString *completedfileSize = [self formartFileSize:completedsize];
    NSString *_fileSize = [self formartFileSize:filesize];
    MovieDownloadSize.text = [NSString stringWithFormat:@"%@/%@",completedfileSize,_fileSize] ;
    
    // downloading percent
    float completepercent =  ((float) completedsize/filesize)*100 ;
    UILabel *MovieDownloadingPercent = (UILabel *)[cell viewWithTag:CMovieDownloadingPercent];
    MovieDownloadingPercent.text = [NSString stringWithFormat:@"%.1f%%",completepercent] ;
    
    // downloading processbar
    UIProgressView *MovieDownloadingBar = (UIProgressView *)[cell viewWithTag:CMovieDownloadingProcessBar];
    //[MovieDownloadingBar setProgress:((float) completedsize/filesize)] ;
    if([MovieDownloadingBar respondsToSelector:@selector(setProgress:animated:)]) {
        [MovieDownloadingBar setProgress:((float) completedsize/filesize) animated:NO];
    }
    else {
        [MovieDownloadingBar setProgress:((float) completedsize/filesize)];
    }
    
    // downloadng speed 9
    //downloadingSpeed
    UILabel *MovieDownloadingSpeed = (UILabel *)[cell viewWithTag:CMovieDownloadSpeed];
    MovieDownloadingSpeed.hidden = ![[[self.downloadedVideos objectAtIndex:row] objectForKey:@"isDownloading"] boolValue] ;
    MovieDownloadingSpeed.text = [[self.downloadedVideos objectAtIndex:row] objectForKey:@"downloadingSpeed"] ;
    
    UIImageView *_statusImageView = (UIImageView *)[cell viewWithTag:CMovieStatusImage];
    
    // 缓存状态文字
    UILabel *MovieDownloadStatus = (UILabel *)[cell viewWithTag:CMovieDownloadingStatus];
    if ([self.CompleteSegSelected boolValue]) {
        MovieDownloadStatus.text = @"已完成";
        _statusImageView.image = [UIImage imageNamed:@"completed"];
    }
    else {
        MovieDownloadStatus.text = @"已暂停";
        _statusImageView.image = [UIImage imageNamed:@"pause"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];//选中后的反显颜色即刻消失
    
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    NSInteger row = [indexPath row];
    
    if ([myapp.downloadVideos objectForKey:[[self.downloadedVideos objectAtIndex:row] objectForKey:@"_m3u8UrlMd5"]] != nil) {   //正在缓存
        [self _cancelDownloadVideo:indexPath];
    } else {    //暂停缓存
        NSMutableDictionary *dic = [self.downloadedVideos objectAtIndex:row];
        [self godownloadTsFiles:[dic objectForKey:@"_m3u8UrlMd5"] indexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
    NSUInteger row = [indexPath row];
    
    NSDictionary *rowData = [self.downloadedVideos objectAtIndex:row] ;
    
    [VideoDownloader removeVideoBySite:[rowData objectForKey:@"site"]
                                withM3u8Url:[rowData objectForKey:@"m3u8Url"]] ;

    [self.downloadedVideos removeObjectAtIndex:row];
    
    [tableView reloadData];
}

-(void) godownloadTsFiles:(NSString *)m3u8UrlMd5 indexPath:(NSIndexPath *)indexPath{
    
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    
    if ([[VideoDownloader getDownloadNums] intValue] != -1 && [[myapp.downloadVideos allKeys] count] >= [[VideoDownloader getDownloadNums] intValue]) {
        // 不再启动缓存任务
        return ;
    }    
    
    NSInteger row = [indexPath row] ;
    //if (![[[self.downloadedVideos objectAtIndex:row] objectForKey:@"isDownloading"] boolValue]) {
    if ([myapp.downloadVideos objectForKey:m3u8UrlMd5] == nil) {
        // 更新按钮状态
        UITableViewCell *cell = [self.downloadTableView cellForRowAtIndexPath:indexPath];
        
        UIImageView *_statusImageView = (UIImageView *)[cell viewWithTag:CMovieStatusImage];
        _statusImageView.image = [UIImage imageNamed:@"downloading"];
        
        UILabel *MovieDownloadStatus = (UILabel *)[cell viewWithTag:CMovieDownloadingStatus];
        MovieDownloadStatus.text = @"缓存中";
        
        [[self.downloadedVideos objectAtIndex:row] setObject:[NSNumber numberWithBool:YES] forKey:@"isDownloading"] ;
        
        // 取到视频信息
        NSMutableDictionary *videoinfo = [NSMutableDictionary dictionary] ;
        [videoinfo setObject:m3u8UrlMd5 forKey:@"m3u8UrlMd5"] ;
        [videoinfo setObject:indexPath forKey:@"indexPath"];
        [myapp addDownloadWithM3u8Md5:m3u8UrlMd5];
    }
}


-(void)_cancelDownloadVideo:(NSIndexPath *)indexPath {
    // 更新按钮状态
    UITableViewCell *cell = [self.downloadTableView cellForRowAtIndexPath:indexPath];
    
    UIImageView *_statusImageView = (UIImageView *)[cell viewWithTag:CMovieStatusImage];
    
    _statusImageView.image = [UIImage imageNamed:@"pause"];
    
    // 更新缓存状态文字
    UILabel *MovieDownloadStatus = (UILabel *)[cell viewWithTag:CMovieDownloadingStatus];
    MovieDownloadStatus.text = @"已暂停";
    
    NSInteger row = [indexPath row] ;
    [[self.downloadedVideos objectAtIndex:row] setObject:[NSNumber numberWithBool:NO] forKey:@"isDownloading"] ;
    NSString *m3u8Md5 = [[self.downloadedVideos objectAtIndex:row] objectForKey:@"_m3u8UrlMd5"];
    
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    [myapp cancelDownload:m3u8Md5];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_navigationBar release];
    [downloadTableView release];
    [super dealloc];
}
@end
