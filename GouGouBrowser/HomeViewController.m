//
//  HomeViewController.m
//  GouGouBrowser
//
//  Created by jia on 13-6-20.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "HomeViewController.h"
#import "AddQuickController.h"

#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

#define columns 3
#define top_space (iPhone5 ? 12 : 20)
#define space 25
#define gridHight 95
#define gridWith 72
#define unValidIndex  -1
#define threshold 30

#define rows (iPhone5 ? 4 : 3)
#define itemsPerPage (iPhone5 ? 12 : 9)
#define PAGER_ORIGIN_Y (iPhone5 ? 35 : 90)

@interface HomeViewController (){
    UIWebView *webView;
    BOOL viewIsDidLoad;
}

-(NSInteger)indexOfLocation:(CGPoint)location;
-(CGPoint)orginPointOfIndex:(NSInteger)index;
-(void) exchangeItem:(NSInteger)oldIndex withposition:(NSInteger) newIndex;
@end

@implementation HomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    CGRect _scroll_frame = CGRectMake(0, 0, _scrollview.frame.size.width, self.view.frame.size.height - 20);
    [_scrollview setFrame:_scroll_frame];
    
    CGRect _page_frame = [_pageControl frame];
    _page_frame.origin.y = _scroll_frame.size.height - PAGER_ORIGIN_Y;
    [_pageControl setFrame:_page_frame];
    
    page = 0;
    isEditing = NO;
    gridItems = [[NSMutableArray alloc] initWithCapacity:6];
    
    addbutton = [[BJGridItem alloc] initWithTitle:@"" withUiImage:[UIImage imageNamed:@"dashboard_websitechannel_background"] withImage:@"dashboard_websitechannel_add" atIndex:0 editable:NO];
    
    [addbutton setFrame:CGRectMake(space, top_space, gridWith, gridHight)];
    
    addbutton.delegate = self;
    [gridItems addObject:addbutton];
    [_scrollview addSubview: addbutton];
    
    _scrollview.delegate = self;
    [_scrollview setPagingEnabled:YES];
    singletap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [singletap setNumberOfTapsRequired:1];
    singletap.delegate = self;
    [_scrollview addGestureRecognizer:singletap];
    
    //初始化 读取plist文件
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSArray *data_arr = [myapp quickLinkList];
    if(nil != data_arr && [data_arr count] != 0){
        int count = [data_arr count];
        for(int i=0;i<count;i++){
            NSMutableDictionary *quickLink = [data_arr objectAtIndex:i];
            NSString *q_title = [quickLink objectForKey:@"title"];
            //            NSString *q_url = [quickLink objectForKey:@"url"];
            NSString *q_img = [quickLink objectForKey:@"image_name"];
            BOOL q_userAdded = [[quickLink objectForKey:@"user_added"] boolValue];
            
            [self Addbutton:q_title withBtnImg:q_img isUserAdded:q_userAdded];
        }
    }
    
    _pageControl.currentPage = 0;
}

//解决pageControl错位
- (void) viewDidAppear:(BOOL)animated {
    CGRect scroll_frame = _scrollview.frame;
    scroll_frame.origin.y = 0;
    [_scrollview setFrame:scroll_frame];
    //    if(!viewIsDidLoad){
    //        [_pageControl setFrame:CGRectMake(0, _scrollview.frame.size.height - 22, _pageControl.frame.size.width, _pageControl.frame.size.height)];
    //        viewIsDidLoad = YES;
    //    } else {
    //        CGRect rect = self.view.frame;
    //        self.view.frame = CGRectMake(rect.origin.x, 44, rect.size.width, 416);
    //    }
}

- (void) viewWillAppear:(BOOL)animated {
    if(viewIsDidLoad){
        //        [_pageControl setFrame:CGRectMake(0, _scrollview.frame.size.height + 20, _pageControl.frame.size.width, _pageControl.frame.size.height)];
    }
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark-- UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    CGPoint offsetofScrollView = scrollView.contentOffset;
    [_pageControl setCurrentPage:offsetofScrollView.x / scrollView.frame.size.width];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    preX = scrollView.contentOffset.x;
}

- (void)Addbutton : (NSString *) btn_title withBtnImg : (NSString *) imgName isUserAdded:(BOOL) isUserAdded {
    CGRect frame = CGRectMake(space, top_space, gridWith, gridHight);
    int n = [gridItems count];
    int row = (n-1) / columns;
    int col = (n-1) % columns;
    
    int curpage = (n-1) / itemsPerPage;
    row = row % rows;
    
    frame.origin.x = frame.origin.x + frame.size.width * col + space * col + _scrollview.frame.size.width * curpage;
    frame.origin.y = frame.origin.y + frame.size.height * row + top_space * row;
    
    UIImage *uiImage;
    if(isUserAdded){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *img_path = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@%@",@"/quick_link/",imgName]];
        NSString *abPath = [documentsDirectory stringByAppendingPathComponent:img_path];
        
//        NSString *trimmedString = [imgName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if([imgName isEqualToString:@""] || NULL == imgName || nil == imgName) {
            uiImage = [UIImage imageNamed : @"default1"];
        } else {
            uiImage = [UIImage imageWithContentsOfFile:abPath];
        }
    } else {
        uiImage = [UIImage imageNamed : imgName];
    }
    
    BJGridItem *gridItem = [[BJGridItem alloc] initWithTitle:btn_title withUiImage:uiImage withImage:NULL atIndex:n-1 editable:YES];
    
    [gridItem setFrame:frame];
    
    gridItem.delegate = self;
    [gridItems insertObject:gridItem atIndex:n-1];
    
    [_scrollview addSubview:gridItem];
    gridItem = nil;
    
    //move the add button
    row = n / columns;
    col = n % columns;
    curpage = n / itemsPerPage;
    row = row % rows;
    frame = CGRectMake(space, top_space, gridWith, gridHight);
    frame.origin.x = frame.origin.x + frame.size.width * col + space * col + _scrollview.frame.size.width * curpage;
    frame.origin.y = frame.origin.y + frame.size.height * row + top_space * row;
    
    _pageControl.numberOfPages = curpage + 1;
    _pageControl.currentPage = curpage + 1;
    
    [_scrollview setContentSize:CGSizeMake(_scrollview.frame.size.width * (curpage + 1), _scrollview.frame.size.height)];
    //跳转后一页
//    [_scrollview scrollRectToVisible:CGRectMake(_scrollview.frame.size.width * curpage, _scrollview.frame.origin.y, _scrollview.frame.size.width, _scrollview.frame.size.height) animated:NO];
    [UIView animateWithDuration:0.2f animations:^{
        [addbutton setFrame:frame];
    }];
    addbutton.index += 1;
    
    
}
#pragma mark-- BJGridItemDelegate
- (void)gridItemDidClicked:(BJGridItem *)gridItem{
    if (gridItem.index == [gridItems count]-1) {
        AddQuickController *controller = [[AddQuickController alloc] init];
        controller.addQuickDelegate = self;
        [self presentViewController:controller animated:YES completion:nil];
    } else {
        //post 通知viewcontrller展示webview
        AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSArray *data_arr = [myapp quickLinkList];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadWeb" object:self userInfo:[data_arr objectAtIndex:gridItem.index]];
        
        [[self view] removeFromSuperview];
        [self release];
    }
}

- (void)gridItemDidDeleted:(BJGridItem *)gridItem atIndex:(NSInteger)index{
    BJGridItem * item = [gridItems objectAtIndex:index];
    
    [gridItems removeObjectAtIndex:index];
    [UIView animateWithDuration:0.2 animations:^{
        CGRect lastFrame = item.frame;
        CGRect curFrame;
        for (int i=index; i < [gridItems count]; i++) {
            BJGridItem *temp = [gridItems objectAtIndex:i];
            curFrame = temp.frame;
            [temp setFrame:lastFrame];
            lastFrame = curFrame;
            [temp setIndex:i];
        }
//        [addbutton setFrame:lastFrame];
    }];
    [item removeFromSuperview];
    item = nil;
    
    int n = [gridItems count];
    NSInteger curpage = n / itemsPerPage;
    int allPage = n % itemsPerPage == 0 ? curpage : curpage + 1;
    _pageControl.numberOfPages = allPage;
    
    [_scrollview setContentSize:CGSizeMake(_scrollview.frame.size.width * allPage, _scrollview.frame.size.height)];
    
    //plist同步删除
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [myapp delQuickLink:index withUrlMD5:nil];
}

- (void)gridItemDidEnterEditingMode:(BJGridItem *)gridItem{
    for (BJGridItem *item in gridItems) {
        [item enableEditing];
    }
    //[addbutton enableEditing];
    isEditing = YES;
    
}
- (void)gridItemDidMoved:(BJGridItem *)gridItem withLocation:(CGPoint)point moveGestureRecognizer:(UILongPressGestureRecognizer *)recognizer{
    /** CGRect frame = gridItem.frame;
     CGPoint _point = [recognizer locationInView:self.scrollview];
     CGPoint pointInView = [recognizer locationInView:self.view];
     frame.origin.x = _point.x - point.x;
     frame.origin.y = _point.y - point.y;
     gridItem.frame = frame;
     NSLog(@"gridItemframe:%f,%f",frame.origin.x,frame.origin.y);
     NSLog(@"move to point(%f,%f)",point.x,point.y);
     
     NSInteger toIndex = [self indexOfLocation:_point];
     NSInteger fromIndex = gridItem.index;
     NSLog(@"fromIndex:%d toIndex:%d",fromIndex,toIndex);
     
     if (toIndex != unValidIndex && toIndex != fromIndex) {
     BJGridItem *moveItem = [gridItems objectAtIndex:toIndex];
     [_scrollview sendSubviewToBack:moveItem];
     [UIView animateWithDuration:0.2 animations:^{
     CGPoint origin = [self orginPointOfIndex:fromIndex];
     //NSLog(@"origin:%f,%f",origin.x,origin.y);
     moveItem.frame = CGRectMake(origin.x, origin.y, moveItem.frame.size.width, moveItem.frame.size.height);
     }];
     [self exchangeItem:fromIndex withposition:toIndex];
     //移动
     
     }
     //翻页
     if (pointInView.x >= _scrollview.frame.size.width - threshold) {
     [_scrollview scrollRectToVisible:CGRectMake(_scrollview.contentOffset.x + _scrollview.frame.size.width, 0, _scrollview.frame.size.width, _scrollview.frame.size.height) animated:YES];
     }else if (pointInView.x < threshold) {
     [_scrollview scrollRectToVisible:CGRectMake(_scrollview.contentOffset.x - _scrollview.frame.size.width, 0, _scrollview.frame.size.width, _scrollview.frame.size.height) animated:YES];
     }
     **/
}

- (void) gridItemDidEndMoved:(BJGridItem *) gridItem withLocation:(CGPoint)point moveGestureRecognizer:(UILongPressGestureRecognizer*) recognizer{
//    CGPoint _point = [recognizer locationInView:self.scrollview];
//    NSInteger toIndex = [self indexOfLocation:_point];
//    if (toIndex == unValidIndex) {
//        toIndex = gridItem.index;
//    }
//    CGPoint origin = [self orginPointOfIndex:toIndex];

//    [UIView animateWithDuration:0.2 animations:^{
//        gridItem.frame = CGRectMake(origin.x, origin.y, gridItem.frame.size.width, gridItem.frame.size.height);
//    }];
}

- (void) handleSingleTap:(UITapGestureRecognizer *) gestureRecognizer{
    if (isEditing) {
        for (BJGridItem *item in gridItems) {
            [item disableEditing];
        }
        [addbutton disableEditing];
    }
    isEditing = NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if(touch.view != _scrollview){
        return NO;
    }else
        return YES;
}

#pragma mark-- private
- (NSInteger)indexOfLocation:(CGPoint)location{
    NSInteger index;
    NSInteger _page = location.x / 320;
    NSInteger row =  location.y / (gridHight + space);
    NSInteger col = (location.x - _page * 320) / (gridWith + space);
    if (row >= rows || col >= columns) {
        return  unValidIndex;
    }
    index = itemsPerPage * _page + row * 2 + col;
    if (index >= [gridItems count]) {
        return  unValidIndex;
    }
    
    return index;
}

- (CGPoint)orginPointOfIndex:(NSInteger)index{
    CGPoint point = CGPointZero;
    if (index > [gridItems count] || index < 0) {
        return point;
    }else{
        NSInteger _page = index / itemsPerPage;
        NSInteger row = (index - _page * itemsPerPage) / columns;
        NSInteger col = (index - _page * itemsPerPage) % columns;
        
        point.x = _page * 320 + col * gridWith + (col +1) * space;
        point.y = row * gridHight + (row + 1) * space;
        return  point;
    }
}

- (void)exchangeItem:(NSInteger)oldIndex withposition:(NSInteger)newIndex{
    ((BJGridItem *)[gridItems objectAtIndex:oldIndex]).index = newIndex;
    ((BJGridItem *)[gridItems objectAtIndex:newIndex]).index = oldIndex;
    [gridItems exchangeObjectAtIndex:oldIndex withObjectAtIndex:newIndex];
}


- (void)dealloc
{
    [_scrollview release], _scrollview = nil;
    [_pageControl release], _pageControl = nil;
    
    [super dealloc];
}

- (void) srceenWebView : (NSString *) withTitle withUrl : (NSString *) url {
    webView = [[UIWebView alloc] initWithFrame:CGRectMake(0,0,10,10)];
    
    webView.delegate = self;
    
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

#pragma mark AddQuickDelegate
- (void) addQuick:(NSString *)title needUrl:(NSString *)url{
    NSLog(@"title is : %@ ----- url is : %@",title, url);
    
    //写入plist文件
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableDictionary *quickLink = [NSMutableDictionary dictionaryWithCapacity:4];
    [quickLink setValue:title forKey:@"title"];
    
    if(![url hasPrefix:@"http://"]){
        url = [@"http://" stringByAppendingString:url];
    }
    
    [quickLink setValue:url forKey:@"url"];
    [quickLink setValue:@"" forKey:@"image_name"];
    [quickLink setValue:[NSNumber numberWithBool:YES] forKey:@"user_added"];
    [quickLink setValue:[url md5] forKey:@"urlMD5"];
    
    [myapp addQuickLink:quickLink];
    
    [self Addbutton:title withBtnImg:NULL isUserAdded:YES];
    [self srceenWebView:title withUrl:url];
}

#pragma mark UIWebView delegate
- (void) webViewDidStartLoad:(UIWebView *) sender {
    [self updateLoadingStatus];
}

- (void) updateLoadingStatus{
    NSString *js_str = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", @"var links = document.getElementsByTagName('link');",@"for(var i=0;i<links.length;i++) {", @"var rel = links[i].getAttribute('rel');",@"if(rel&&(rel=='apple-touch-icon' || rel=='apple-touch-icon-precomposed')){",@"links[i].getAttribute('href'); }}"];
    
    NSString *icon_url = [webView stringByEvaluatingJavaScriptFromString:js_str];
    
    if (![icon_url isEqualToString:@""]) {
        NSLog(@"%@", icon_url);
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLoadingStatus) object:nil];
        
        NSURL *url = [NSURL URLWithString:icon_url];
        httpRequest=[ASIHTTPRequest requestWithURL:url];
        [httpRequest setDelegate:self];
        //开始异步下载
        [httpRequest startAsynchronous];
        
        [self releaseWebView];
    }
}

- (void) webViewDidFinishLoad:(UIWebView *) sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLoadingStatus) object:nil];
    [self performSelector:@selector(updateLoadingStatus) withObject:nil afterDelay:1.];
}

- (void) webView:(UIWebView *)sender didFailLoadWithError:(NSError *) error {
    BJGridItem * item = [gridItems objectAtIndex:([gridItems count] - 2)];
    [item reloadBackgound:[UIImage imageNamed:@""]];
    
    [self releaseWebView];
}

- (void) releaseWebView {
    [webView setDelegate:nil];
    [webView stopLoading];
    [webView release];
}

#pragma mark ASIHttpRequest delegate
- (void) requestFinished:(ASIHTTPRequest *)request {
    NSError *error=[request error];
    if (!error) {
        NSString *icon_url = [[request url] absoluteString];
        NSData *imageData = [request responseData];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *fileName = [icon_url md5];
        fileName = [fileName stringByAppendingString:@".png"];
        
        NSString *pathFloder = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@%@",@"/quick_link/",fileName]];
        
        NSString *defaultDBPath = [documentsDirectory stringByAppendingPathComponent:pathFloder];
        
        [imageData writeToFile:defaultDBPath atomically:YES];
        
        //替换背景图
        BJGridItem * item = [gridItems objectAtIndex:([gridItems count] - 2)];
        [item reloadBackgound:[UIImage imageWithContentsOfFile:defaultDBPath]];
        
        //修改plist
        AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSArray *data_arr = [myapp quickLinkList];
        NSMutableDictionary *quick = [data_arr objectAtIndex:[gridItems count] - 2];
        [quick setValue:fileName forKey:@"image_name"];
        [myapp editQuickLink:quick withIndex:[gridItems count] - 2];
    } else {
        BJGridItem * item = [gridItems objectAtIndex:([gridItems count] - 2)];
        [item reloadBackgound:[UIImage imageNamed:@""]];
    }
}

- (void) requestFailed:(ASIHTTPRequest *)request {
    BJGridItem * item = [gridItems objectAtIndex:([gridItems count] - 2)];
    [item reloadBackgound:[UIImage imageNamed:@""]];
}

@end