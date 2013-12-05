//
//  ViewController.m
//  GouGouBrowser
//
//  Created by jia on 13-6-20.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "ViewController.h"

#define FINAL_CAPTURE_INDEX 30

@interface ViewController (){
    BOOL inHome, keyboardShown;
    NSInteger capture_index;    //抓取次数
    BOOL isAdd; //是否在一次请求中添加历史记录
}

@end

@implementation ViewController

@synthesize imageView, searchBtn, text_url, webView, stopReloadButton, cancelBtn, table, listData, notify, showPopBtn, bgView, refreshTimer, loadingAlert, hud;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //历史记录
    self.listData = [VideoDownloader selectHistory:0 withLimit:7];
    
    //toolbar
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:9];
    
    //后退
    UIButton *uibtn_back = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 31, 31)];
    [uibtn_back setBackgroundImage:[UIImage imageNamed:@"previousbutton_disabled"] forState:UIControlStateDisabled];
    [uibtn_back setBackgroundImage:[UIImage imageNamed:@"previousbutton_normal"] forState:UIControlStateNormal];
    [uibtn_back addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    _btn_back = [[UIBarButtonItem alloc] initWithCustomView:uibtn_back];
    _btn_back.enabled = NO;
    [uibtn_back release];
    
    //前进
    UIButton *uibtn_go = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 31, 31)];
    [uibtn_go setBackgroundImage:[UIImage imageNamed:@"nextbutton_disabled"] forState:UIControlStateDisabled];
    [uibtn_go setBackgroundImage:[UIImage imageNamed:@"nextbutton_normal"] forState:UIControlStateNormal];
    [uibtn_go addTarget:self action:@selector(goForward:) forControlEvents:UIControlEventTouchUpInside];
    _btn_go = [[UIBarButtonItem alloc] initWithCustomView:uibtn_go];
    _btn_go.enabled = NO;
    [uibtn_go release];
    
    UIBarButtonItem *flexibleSpaceButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace                                                                                    target:nil action:nil] autorelease];

    //主页
    UIButton *uibtn_home = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 31, 31)];
    [uibtn_home setBackgroundImage:[UIImage imageNamed:@"topbar_homepagebutton_normal"] forState:UIControlStateNormal];
    [uibtn_home addTarget:self action:@selector(showHome) forControlEvents:UIControlEventTouchUpInside];
    _btn_home = [[UIBarButtonItem alloc] initWithCustomView:uibtn_home];
    _btn_home.enabled = NO;
    [uibtn_home release];
    
    //历史纪录
    UIButton *uibtn_setting = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 31, 31)];
    [uibtn_setting setBackgroundImage:[UIImage imageNamed:@"topbar_menuactionbutton_normal"] forState:UIControlStateNormal];
    [uibtn_setting addTarget:self action:@selector(showHistory) forControlEvents:UIControlEventTouchUpInside];
    _btn_setting = [[UIBarButtonItem alloc] initWithCustomView:uibtn_setting];
    [uibtn_setting release];
    
    //书签
    UIButton *uibtn_bookmar = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 31, 31)];
    [uibtn_bookmar setBackgroundImage:[UIImage imageNamed:@"topbar_bookmarkbutton_normal"] forState:UIControlStateNormal];
    [uibtn_bookmar addTarget:self action:@selector(showBookmark) forControlEvents:UIControlEventTouchUpInside];
    _btn_bookmark = [[UIBarButtonItem alloc] initWithCustomView:uibtn_bookmar];
    [uibtn_bookmar release];
    
    //下载文件
    UIButton *uibtn_files = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 27, 27)];
    [uibtn_files setBackgroundImage:[UIImage imageNamed:@"actionpanel_file_normal"] forState:UIControlStateNormal];
    [uibtn_files addTarget:self action:@selector(showDownload) forControlEvents:UIControlEventTouchUpInside];
    _btn_files = [[UIBarButtonItem alloc] initWithCustomView:uibtn_files];
    [uibtn_files release];
    
    [buttons addObject:_btn_back];
    [buttons addObject:_btn_go];
    [buttons addObject:flexibleSpaceButtonItem];
    [buttons addObject:_btn_home];
    [buttons addObject:_btn_setting];
    [buttons addObject:_btn_bookmark];
    [buttons addObject:_btn_files];
    
    [_toolBar setItems:buttons];
    
    //badge set
    CGRect rect = [[_btn_files customView] frame];
    bgView = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(rect.origin.x + 15, rect.origin.y - 4, 18, 18)];
    bgView.hideWhenZero = YES;
    bgView.value = 0;
    bgView.pad = 1;
    bgView.strokeWidth = 1;
    bgView.font = [UIFont boldSystemFontOfSize:12];
    bgView.shadow = NO;
    [_toolBar addSubview:bgView];
    [bgView release];
    
    /** header setup**/
    //输入框
    text_url = [[AddressTextField alloc] initWithFrame:CGRectMake(43, 26, 265, 31)];
    [text_url setPlaceholder:@"输入网址"];
    [text_url setKeyboardType:UIKeyboardTypeURL];
    [text_url setReturnKeyType:UIReturnKeyGo];
    [text_url setClearButtonMode:UITextFieldViewModeWhileEditing];
    [text_url setFont:[UIFont systemFontOfSize:12.0]];
    text_url.isLong = YES;
    
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 2.5, 0, 2.5);
    UIImage *input_back = [UIImage imageNamed:@"textfield_border_righthalf"];
    input_back = [input_back resizableImageWithCapInsets:insets];
    [text_url setBackground:input_back];
    [text_url setBackgroundColor:[UIColor whiteColor]];
    //居中
    text_url.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    text_url.delegate = self;
    [imageView addSubview:text_url];

    //搜索按钮
//    searchBtn = [[UIButton alloc] initWithFrame:CGRectMake(280, 6, 27, 32)];
//    searchBtn = [[UIButton alloc] initWithFrame:CGRectMake(280, 26, 27, 32)];
//    [searchBtn setBackgroundImage:[UIImage imageNamed:@"search@2x.png"] forState:UIControlStateNormal];
//    [imageView addSubview:searchBtn];
//    [searchBtn release];
    
    //homeview setup
    HomeViewController *home_view = [[HomeViewController alloc] initWithNibName:@"HomeViewController" bundle:nil];
    
    home_view.view.frame = CGRectMake(0,imageView.frame.size.height,self.view.frame.size.width,                            self.view.frame.size.height - imageView.frame.size.height - _toolBar.frame.size.height);
    [[home_view view] setTag:57];
    [[self view] addSubview:home_view.view];
    [self addChildViewController:home_view];
    
    inHome = YES;
    
    //注册通知 用于点击快捷链接后回调展示webview
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(loadWeb:)
               name:@"loadWeb"
             object:nil];
    
    //注册通知 操作历史纪录后刷新table list data
    NSNotificationCenter *nc2 = [NSNotificationCenter defaultCenter];
    [nc2 addObserver:self
           selector:@selector(reload_data:)
               name:@"reload_data"
             object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [super viewWillDisappear:animated];
}

#define MASKVIEWTAG 99
- (void)keyboardWillShow:(NSNotification*)aNotification
{
    NSLog(@"show keyboard");

    if (keyboardShown || !text_url.isFirstResponder)
        return;
    
    NSDictionary* info = [aNotification userInfo];
    NSValue* aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    //键盘的大小
    CGSize keyboardRect = [aValue CGRectValue].size;
    
    //计算覆盖上去的UIView的区域，因为键盘始终是在上面的，所以UIView *maskView下面可以大些，主要不要盖住上面的searchBar之类的内容。要显示结果的UITableView的大小则要根据键盘的大小算出确切的中间区域
    UIView *maskView = [[UIView alloc]initWithFrame:CGRectMake(0.0f, imageView.frame.size.height, 320.0f, self.view.frame.size.height - imageView.frame.size.height - keyboardRect.height)];
    [maskView setBackgroundColor:[UIColor grayColor]];
    [maskView setTag:MASKVIEWTAG];
    
    //add cancel btn
    CGRect text_url_frame = text_url.frame;
//    cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(text_url_frame.origin.x + text_url_frame.size.width + 42, text_url_frame.origin.y, 38, 30)];
    cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(text_url.frame.origin.x + text_url.frame.size.width - 42, text_url.frame.origin.y, 50, 30)];
    
    [cancelBtn setTitle:@"取 消" forState:UIControlStateNormal];
    UIColor *color = [UIColor colorWithRed:38/255.0 green:45/255.0 blue:58/255.0 alpha:1.0];
    //title 颜色
    [cancelBtn setTitleColor:color forState:UIControlStateNormal];
    //title 字体大小
    [[cancelBtn titleLabel] setFont:[UIFont systemFontOfSize: 12.0]];
    [cancelBtn addTarget:self action:@selector(closeMaskView:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImage *originalImage = [UIImage imageNamed:@"button_defaultstyle_background_normal"];
    UIImage *originalImage2 = [UIImage imageNamed:@"button_defaultstyle_background_highlighted"];
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 2.5, 0, 2.5);
    UIImage *imgBack = [originalImage resizableImageWithCapInsets:insets];
    UIImage *imgBack2 = [originalImage2 resizableImageWithCapInsets:insets];
    [cancelBtn setBackgroundImage:imgBack forState:UIControlStateNormal];
    [cancelBtn setBackgroundImage:imgBack2 forState:UIControlStateHighlighted];
    
    [imageView addSubview:cancelBtn];
    [cancelBtn release];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.1];          //动画持续的时间
    //hello
    //这里添加你对UIView所做改变的代码
    text_url_frame.size.width -= 50;
    text_url.frame = text_url_frame;
    text_url.isLong = NO;
    
    //[UIView setAnimationDidStopSelector:@selector(animationFinished:)];   //动画停止后，执行某个方法
    [UIView commitAnimations];
    
    //add tableview
    CGRect m_frame = maskView.frame;
    m_frame.origin.y = 0;    
    table = [[UITableView alloc] initWithFrame:m_frame];
    table.delegate = self;
    table.dataSource = self;
    [maskView addSubview:table];
    
    [self.view addSubview:maskView];
    
    [self.view.window bringSubviewToFront:maskView];

    keyboardShown = YES;
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    NSLog(@"hide keyboard");
//    [text_url resignFirstResponder];
}

- (void)closeMaskView:(id)sender
{
    NSLog(@"BTN CLICK");
    
    [text_url resignFirstResponder];
    if(!keyboardShown)
        return;
    [[self.view viewWithTag:MASKVIEWTAG]removeFromSuperview];
    [cancelBtn removeFromSuperview];
    
    CGRect text_url_frame = text_url.frame;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.1];          //动画持续的时间
    
    //这里添加你对UIView所做改变的代码
    text_url_frame.size.width += 50;
    text_url.frame = text_url_frame;
    text_url.isLong = YES;
    
    //[UIView setAnimationDidStopSelector:@selector(animationFinished:)];   //动画停止后，执行某个方法
    [UIView commitAnimations];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView commitAnimations];
    keyboardShown = NO;
}

//点击灰色的视窗 响应TableView的选择点击等行为
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if([self.view viewWithTag:MASKVIEWTAG]) //置毁视窗存在时
    {
        [self keyboardWillHide:nil];
    }
}

- (void) loadWeb :(NSNotification*)sender{
    NSMutableDictionary *quickInfo = [NSMutableDictionary dictionaryWithDictionary:[sender userInfo]];
    NSString *str_url = [quickInfo objectForKey:@"url"];
    
//    NSLog(@"%@: %@",[quickInfo objectForKey:@"title"],str_url);
    
    NSURL *url = [NSURL URLWithString:str_url];
        
    [self loadRequest:url];
}

- (void) reload_data : (NSNotification*)sender{
    self.listData = [VideoDownloader selectHistory:0 withLimit:7];
}

- (void) loadRequest : (NSURL *) url{
    if(inHome){ //加载webview
        UIView *homeView = [[self view] viewWithTag:57];
        [homeView removeFromSuperview];

        // webView
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, imageView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - imageView.frame.size.height - _toolBar.frame.size.height - 1)];
        webView.scalesPageToFit = YES;
        webView.contentMode = UIViewContentModeScaleToFill;
        webView.multipleTouchEnabled = YES;
        webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        webView.delegate = self;
        
        // reloadButton
        stopReloadButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        stopReloadButton.bounds = CGRectMake(0, 0, 26, 30);
        [stopReloadButton setImage:[UIImage imageNamed:@"AddressViewReload"] forState:UIControlStateNormal];
        stopReloadButton.showsTouchWhenHighlighted = NO;
        [stopReloadButton addTarget:self action:@selector(reloadOrStop:) forControlEvents:UIControlEventTouchUpInside];
        text_url.rightView = stopReloadButton;
        text_url.rightViewMode = UITextFieldViewModeUnlessEditing;
        
        [self.view addSubview:webView];
        
        inHome = NO;
        _btn_home.enabled = YES;
    }
    
    [text_url setText:[url absoluteString]];
    
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void) showHome {
    [notify hide];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if(!inHome){
        [webView stopLoading];
        [webView setDelegate:nil];
        [webView release];
        [webView removeFromSuperview];
        webView = nil;
        
        inHome = YES;
        _btn_home.enabled = NO;
        _btn_back.enabled = NO;
        _btn_go.enabled = NO;
        
        text_url.text = @"";
        text_url.rightView = nil;
        
        if(nil != refreshTimer) {
            [refreshTimer invalidate];
        }
        
        HomeViewController *home_view = [[HomeViewController alloc] initWithNibName:@"HomeViewController" bundle:nil];
        home_view.view.frame = CGRectMake(0,imageView.frame.size.height,self.view.frame.size.width,                            self.view.frame.size.height - imageView.frame.size.height - _toolBar.frame.size.height);
        [[home_view view]setTag:57];
        [[self view] addSubview:home_view.view];
        [self addChildViewController:home_view];
    }
}

- (void) showDownload {
    if(nil != refreshTimer) {
        [refreshTimer invalidate];
    }
    
    [notify hide];
    bgView.value = 0;
    DownloadViewController *downloadView = [[DownloadViewController alloc] init];
    [self presentViewController:downloadView animated:YES completion:nil];
}

- (void) showBookmark {
    if(nil != refreshTimer) {
        [refreshTimer invalidate];
    }
    
    [notify hide];
    BookMarkViewController *controller = [[BookMarkViewController alloc] init];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void) showHistory {
    if(nil != refreshTimer) {
        [refreshTimer invalidate];
    }
    
    [notify hide];
    HistoryViewController *controller = [[HistoryViewController alloc] init];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void) clickCtrl : (NSString *) m3u8Url withTitle :(NSString *) title isDownload : (NSInteger) hasDownload {
    if(1 == hasDownload) {
        NSString *_m3u8Md5 = [[NSString stringWithFormat:@"%@_%@",[text_url text], m3u8Url] md5];
//        NSLog(@"%@",_m3u8Md5);
        NSString *localPlayUrl = [NSString stringWithFormat:@"http://127.0.0.1:12345/%@/playlist.m3u8",_m3u8Md5];
        VideoPlayerVieoController *playView = [[VideoPlayerVieoController alloc] initWithContentURL:[NSURL URLWithString:localPlayUrl]];
        [self presentMoviePlayerViewControllerAnimated:playView];
        //[playView release];
        //playView = nil;
    } else if(2 == hasDownload){
        [self goDownload:m3u8Url withTitle:title];
    } else {
        [self showDownload];
    }
}

#define CMovieInQueueMax 6
-(void)goDownload : (NSString *) m3u8Url withTitle :(NSString *) title
{    
    NSArray *_tmp = [[NSArray alloc] initWithContentsOfFile:[VideoDownloader downloadWhilePlayFilePath]] ;
    int queue_count = [VideoDownloader getAllDownloadVideosCount:NO];
    if (queue_count >= CMovieInQueueMax) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"同时缓存过多资源会影响您的体验，请先清理部分未完成缓存的资源后再添加新的缓存。" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles: nil];
        [alert show];
        [alert release];
        
        return ;
    }
    else {
        NSDictionary *downloadInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      title, @"videoTitle",
                                      [text_url text], @"site",
                                      m3u8Url, @"m3u8Url",
                                      @"bbbaaa", @"playUrl",
                                      nil] ;
        
        AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
        [myapp addDownload:downloadInfo delegate:self];
        
        int bgViewValue = bgView.value;
        bgView.value = ++bgViewValue;
        
        return ;
    }
    [_tmp release];    
}

- (void) updateLocationField {
    NSString *location = webView.request.URL.absoluteString;
    if (location.length)
        text_url.text = webView.request.URL.absoluteString;
}

- (void)reloadOrStop:(id) sender {
    if (webView.loading){
        NSLog(@"111111");
        [webView stopLoading];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [refreshTimer invalidate];
        [stopReloadButton setImage:[UIImage imageNamed:@"AddressViewReload"] forState:UIControlStateNormal];
    }
    else {
        NSLog(@"222222");
        [webView reload];
        [self closeMaskView:nil];
    }
}

- (void) updateLoadingStatus {
    UIImage *image = nil;
    if (webView.loading) {
        image = [UIImage imageNamed:@"AddressViewStop"];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    } else {
        image = [UIImage imageNamed:@"AddressViewReload"];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
    
    [stopReloadButton setImage:image forState:UIControlStateNormal];
    
    // update status of back/forward buttons
    _btn_back.enabled = [webView canGoBack];
    _btn_go.enabled = [webView canGoForward];
}

- (void)goBack:(id) sender {
    [notify hide];
    [webView goBack];
    
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLocationField) object:nil];
//    [self performSelector:@selector(updateLocationField) withObject:nil afterDelay:1.];
}

- (void)goForward:(id) sender {
    [notify hide];
    [webView goForward];
    
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLocationField) object:nil];
//    [self performSelector:@selector(updateLocationField) withObject:nil afterDelay:1.];
}

-(void) refreshDownload {
    
    NSString *videosCmd = @"var _QigouVideos=document.getElementsByTagName('video');" ;
    NSString *resetPlayCmd = @"if(_QigouVideos.length > 0) {_QigouVideos[0].src;}" ;
    
    if(capture_index == FINAL_CAPTURE_INDEX) {
        [refreshTimer invalidate];
    }
    
    NSLog(@"load m3u8, %ld", (long)capture_index);
    capture_index++;
    
    NSString *cmd = [NSString stringWithFormat:@"%@ %@" ,videosCmd,resetPlayCmd];
    
    NSString *m3u8Str = [webView stringByEvaluatingJavaScriptFromString:cmd];
    
    NSString *web_title =  [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    NSString *web_url = [[[webView request] URL] absoluteString];
    if(nil != web_title && !isAdd && ![web_title isEqualToString:@""] && ![web_url isEqualToString:@""]) {
        [VideoDownloader addHistory:web_url withTitle:web_title];
        self.listData = [VideoDownloader selectHistory:0 withLimit:7];
        isAdd = YES;
    }
    
//    NSLog(@"%@", web_title);
    if (![m3u8Str isEqualToString:@""]) {
        NSLog(@"capture!");
        //抓去到m3u8,停止循环
        [refreshTimer invalidate];
        
        //如果已经下载，点击直接播放
        NSArray *arr = [VideoDownloader getVideoWithM3u8Url:m3u8Str site:[text_url text]];
        NSString *str = @"";
        
        NSInteger hadDownload = 0;
        NSMutableDictionary *video;
        
        if([arr count] == 0){
            hadDownload = 2;
            str = @"喜欢该视频?点我开始下载!";
        } else {
            video = arr[0];
            
            NSString *status = [video valueForKey:@"status"];
            if([status isEqualToString:@"1"]) { //已下载
                str = @"该视频已下载到本地,点击直接播放!";
                hadDownload = 1;
                m3u8Str = [video valueForKey:@"m3u8Url"];
            } else {    //下载队列
                str = @"该视频已在下载队列,请耐心等待!";
                hadDownload = 3;
            }
        }
        
        //取到m3u8路径后弹出层
        notify = [[JSNotifier alloc]initWithTitle:str];
        [notify show];
        
        //点击触发
        [notify whenTapped:^{
            [notify hide];
            [self clickCtrl:m3u8Str withTitle:web_title isDownload:hadDownload];
        }];
    }
}

#pragma mark UIWebView delegate

- (void) webViewDidStartLoad:(UIWebView *) sender {
    [notify hide];
    isAdd = NO;
    
    NSTimeInterval _timeInterval = 1;
    capture_index = 0;
    [self.refreshTimer invalidate];
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:_timeInterval target:self selector:@selector(refreshDownload) userInfo:nil repeats:YES];
    
    [self updateLocationField];
    [self updateLoadingStatus];
}

- (void) webViewDidFinishLoad:(UIWebView *) sender {
    // Disable the defaut actionSheet when doing a long press
    [webView stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none';"];
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
    
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLocationField) object:nil];
//    [self performSelector:@selector(updateLocationField) withObject:nil afterDelay:1.];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLoadingStatus) object:nil];
    [self performSelector:@selector(updateLoadingStatus) withObject:nil afterDelay:1.];
}

- (void) webView:(UIWebView *)sender didFailLoadWithError:(NSError *) error {
    switch ([error code]) {
        case kCFURLErrorCancelled :
        {
            // Do nothing in this case
            break;
        }
        default:
        {
            //todo.. load网页错误
            break;
        }
    }
    
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLocationField) object:nil];
//    [self performSelector:@selector(updateLocationField) withObject:nil afterDelay:1.];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLoadingStatus) object:nil];
//    [self performSelector:@selector(updateLoadingStatus) withObject:nil afterDelay:1.];
}

#pragma mark UITextfield delegate
- (BOOL) textFieldShouldReturn:(UITextField *)textField{
    NSURL *url = [NSURL URLWithString:text_url.text];
    // if user didn't enter "http", add it the the url
    if (!url.scheme.length) {
        url = [NSURL URLWithString:[@"http://" stringByAppendingString:text_url.text]];
    }
    
    [self closeMaskView:nil];
    [self loadRequest:url];

    return YES;
}

#pragma mark Table View Data Source Methods
//返回行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.listData count];
}

//新建某一行并返回
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *TableSampleIdentifier = @"TableSampleIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TableSampleIdentifier];
    
    if (cell == nil) {
        UIImage *img = [UIImage imageNamed:@"tabbutton_defaulticon_normal"];
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TableSampleIdentifier];
        cell.imageView.image = img;
        
        UILabel *lab_title = [[UILabel alloc] initWithFrame:CGRectMake(40, 2, 200, 20)];
        [lab_title setFont:[UIFont systemFontOfSize: 14.0]];
        [lab_title setTag:55];
        
        UILabel *lab_url = [[UILabel alloc] initWithFrame:CGRectMake(40,20,200,20)];
        [lab_url setTextColor:[UIColor grayColor]];
        [lab_url setFont:[UIFont systemFontOfSize: 12.0]];
        [lab_url setTag:56];
        
        [[cell contentView] addSubview:lab_title];
        [[cell contentView] addSubview:lab_url];
        [lab_title release];
        [lab_url release];
    }
    
    NSUInteger row = [indexPath row];
    NSMutableDictionary *dic = [listData objectAtIndex:row];
    UILabel *lab_title = (UILabel *)[cell.contentView viewWithTag:55];
    lab_title.text = [dic objectForKey:@"title"];
    UILabel *lab_url = (UILabel *)[cell.contentView viewWithTag:56];
    lab_url.text = [dic objectForKey:@"url"];
    
    cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:96/255.0 green:162/255.0 blue:255/255.0 alpha:1.0];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath{
   
    [tableView deselectRowAtIndexPath:indexPath animated:YES];//选中后的反显颜色即刻消失
    
    NSUInteger row = [indexPath row];
    NSMutableDictionary *dic = [listData objectAtIndex:row];
//    NSLog(@"%@ : %@",[dic objectForKey:@"title"],[dic objectForKey:@"url"]);
    NSString *url_str = [dic objectForKey:@"url"];
    NSURL *url = [NSURL URLWithString:url_str];
    
    [self closeMaskView:nil];
    
    [self loadRequest:url];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return [super shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (void) didReceiveMemoryWarning{
    NSLog(@"warning!");
}

- (void)dealloc {
    [_toolBar release],_toolBar = nil;
    [_btn_back release],_btn_back = nil;
    [_btn_go release],_btn_go = nil;
    [_btn_home release],_btn_home = nil;
    [_btn_setting release],_btn_setting = nil;
    [_btn_bookmark release],_btn_bookmark = nil;
    [_btn_files release],_btn_files = nil;
    
    [searchBtn release], searchBtn = nil;
    [text_url release], text_url = nil;
    [webView release], webView = nil;
    [imageView release];
    [showPopBtn release];
    [_toolBar release];
    [super dealloc];
}

- (IBAction)showPop:(id)sender {
    UIButton *btn = (UIButton *) sender;
    NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity : 2];
    if(!inHome) {
        NSURL *url_url = [[webView request] URL];
        
        AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
        NSString *url = [url_url absoluteString];
        if(![myapp bookMarkExist:[url md5]]){
            [menuItems addObject : [KxMenuItem menuItem:@"添加至书签"
                                                  image:[UIImage imageNamed:@"addpanel_addtobookmark_normal"]
                                                 target:self
                                                 action:@selector(pushMenuItem:)                                                    key:@"bookmark"]];
        } else {
            [menuItems addObject : [KxMenuItem menuItem:@"移除书签"
                                                  image:[UIImage imageNamed:@"addpanel_addtobookmark_normal"]
                                                 target:self
                                                 action:@selector(pushMenuItem:)                                                    key:@"bookmark_del"]];
        }
        
        if(![myapp quickLinkExist:[url md5]]) {
            [menuItems addObject : [KxMenuItem menuItem:@"添加快捷链接"
                                                  image:[UIImage imageNamed:@"addpanel_addtodashboard_normal"]
                                                 target:self
                                                 action:@selector(pushMenuItem:)                                                    key:@"quicklink"]];
        } else {
            [menuItems addObject : [KxMenuItem menuItem:@"移除快捷链接"
                                                  image:[UIImage imageNamed:@"addpanel_addtodashboard_normal"]
                                                 target:self
                                                 action:@selector(pushMenuItem:)                                                    key:@"quicklink_del"]];
        }
    } else {
        [menuItems addObject : [KxMenuItem menuItem:@"无动作"                                                      image:nil
           target:self
           action:nil
              key:nil]];
    }
    [KxMenu showMenuInView:self.view
                  fromRect:btn.frame
                 menuItems:menuItems];

}

- (void) pushMenuItem:(id)sender
{
    KxMenuItem *item = sender;
    NSString *key = item.key;
    
    NSString *title =  [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSURL *url_url = [[webView request] URL];
    NSString *url = [url_url absoluteString];
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *str = @"";
    
    if([key isEqualToString:@"bookmark"]){
        NSMutableDictionary *dic = [[NSMutableDictionary alloc]initWithObjectsAndKeys:title,@"title",
                                    url,@"url",
                                    [url md5],@"urlMD5",nil];
        [myapp addBookMark:dic];
        [dic release];
        str = @"添加书签成功";

    } else if([key isEqualToString:@"bookmark_del"]){
        [myapp delBookMark:-1 withUrlMD5:[url md5]];
        str = @"移除书签成功";
    } else if([key isEqualToString:@"quicklink"]) {
        str = @"添加快捷链接成功";
        
        NSMutableDictionary *quickLink = [NSMutableDictionary dictionaryWithCapacity:4];
        [quickLink setValue:title forKey:@"title"];
        [quickLink setValue:url forKey:@"url"];
        [quickLink setValue:[NSNumber numberWithBool:YES] forKey:@"user_added"];
        
        NSString *js_str = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", @"var links = document.getElementsByTagName('link');",@"for(var i=0;i<links.length;i++) {", @"var rel = links[i].getAttribute('rel');",@"if(rel&&(rel=='apple-touch-icon' || rel=='apple-touch-icon-precomposed')){",@"links[i].getAttribute('href'); }}"];
        
        NSString *icon_url = [webView stringByEvaluatingJavaScriptFromString:js_str];
        
        if (![icon_url isEqualToString:@""]) {
            NSLog(@"%@", icon_url);
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLoadingStatus) object:nil];
            
            hud = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:hud];
            
            //如果设置此属性则当前的view置于后台
            hud.dimBackground = YES;
            
            //设置对话框文字
            //        hud.labelText = @"请稍等";
            
            //显示对话框
            [hud showAnimated:YES whileExecutingBlock:^{
                //对话框显示时需要执行的操作
                NSURL *url = [NSURL URLWithString:icon_url];
                httpRequest=[ASIHTTPRequest requestWithURL:url];
                [httpRequest setDelegate:self];
                //开始同步下载
                [httpRequest startSynchronous];
                
                NSError *error = [httpRequest error];
                
                if(!error) {
                    NSString *icon_url = [[httpRequest url] absoluteString];
                    NSData *imageData = [httpRequest responseData];
                    
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
                    
                    NSString *documentsDirectory = [paths objectAtIndex:0];
                    
                    NSString *fileName = [icon_url md5];
                    fileName = [fileName stringByAppendingString:@".png"];
                    
                    NSString *pathFloder = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@%@",@"/quick_link/",fileName]];
                    
                    NSString *defaultDBPath = [documentsDirectory stringByAppendingPathComponent:pathFloder];
                    
                    [imageData writeToFile:defaultDBPath atomically:YES];
                    
                    [quickLink setValue:fileName forKey:@"image_name"];
                } else {
                    [quickLink setValue:@"" forKey:@"image_name"];
                }
                [myapp addQuickLink:quickLink];
            } completionBlock:^{
                //操作执行完后取消对话框
                [hud removeFromSuperview];
                [hud release];
                hud = nil;
            }];
        } else {
            [quickLink setValue:@"" forKey:@"image_name"];
            [myapp addQuickLink:quickLink];
        }
        
    } else if([key isEqualToString:@"quicklink_del"]) {
        str = @"移除快捷链接成功";
    }
    
    JSNotifier *suc_notify = [[JSNotifier alloc]initWithTitle:str];
    [suc_notify showFor:2];
    [suc_notify release];
}

@end
