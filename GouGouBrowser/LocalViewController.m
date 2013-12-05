//
//  LocalViewController.m
//  GouGouBrowser
//
//  Created by jia on 13-7-9.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "LocalViewController.h"

#define v_title 1
#define v_time 2
#define v_size 3

@interface LocalViewController (){
    NSInteger index;
}

@end

@implementation LocalViewController

@synthesize selectIndex;

@synthesize localVideoCell, downloadedVideos;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    navigationItem = [[UINavigationItem alloc] init];
    UIColor *color = [UIColor colorWithRed:73/255.0 green:78/255.0 blue:90/255.0 alpha:1.0];

    UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    titleView.text = @"已下载";
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
    [btn_close setTitle:@"返 回" forState:UIControlStateNormal];
    [btn_close setBackgroundImage:stretchableImage forState:UIControlStateNormal];
    [[btn_close titleLabel] setFont:textfont];
    [[btn_close titleLabel] setTextColor:[UIColor whiteColor]];
    [btn_close addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    
    closeButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btn_close];
    
    navigationItem.leftBarButtonItem = closeButtonItem;
    
    _navigation_bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [_navigation_bar setItems:[NSArray arrayWithObject:navigationItem]];
    
    //data
    NSDictionary *downloadInfo = [VideoDownloader getAllDownloadVideos:[NSNumber numberWithInt:1]] ;
    self.downloadedVideos = [downloadInfo objectForKey:@"videos"] ;
}

- (void)dismiss:(id)sender
{
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.type = kCATransitionReveal;
    animation.duration = 0.7;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.subtype = kCATransitionFromRight;
    [self.view.window.layer addAnimation:animation forKey:nil];
    
    [self dismissViewControllerAnimated:NO completion:nil];
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


#pragma mark - Table view data source
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [downloadedVideos count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *TableSampleIdentifier = @"LocalVideoCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TableSampleIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LocalVideoCell" owner:self options:nil];
        if ([nib count] > 0) {
            cell = self.localVideoCell;
        } else {
            NSLog(@"failed to load CustomCell nib file!");
        }
    }
    
    NSInteger row = [indexPath row] ;
    
    UILabel *videoTitle = (UILabel *)[cell viewWithTag:v_title];
    videoTitle.text = [[self.downloadedVideos objectAtIndex:row] objectForKey:@"videoTitle"];
    
    UILabel *videoTime = (UILabel *) [cell viewWithTag:v_time];
    videoTime.text = [[self.downloadedVideos objectAtIndex:row] objectForKey:@"lastUpdateTime"];
    
    int filesize = [[[self.downloadedVideos objectAtIndex:row] objectForKey:@"_filesize"] intValue];
    UILabel *videoSize = (UILabel *)[cell viewWithTag:v_size];
    videoSize.text = [self formartFileSize:filesize];
    
    //下边框
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, cell.frame.size.height, cell.frame.size.width, 1.0f);
    bottomBorder.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    [[cell layer]addSublayer:bottomBorder];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self delVideo:indexPath];
    }
    
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

//- (void) delVideo : (NSInteger) i {
- (void) delVideo : (NSIndexPath *) i {
    //删除本地文件
    [VideoDownloader removeVideoBySite:[[self.downloadedVideos objectAtIndex:[i row]] objectForKey:@"site"] withM3u8Url:[[self.downloadedVideos objectAtIndex:[i row]] objectForKey:@"m3u8Url"]];
    
    [self.downloadedVideos removeObjectAtIndex:[i row]];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:i] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_tableView release];
    [_navigation_bar release];
    [localVideoCell release];
    [super dealloc];
}

- (IBAction)openSubView:(id)sender {
    UIButton *btn = (UIButton *) sender ;
    UITableViewCell *cell = (UITableViewCell *)[[[btn superview] superview] superview];
    
//    BOOL test = [[btn superview] isKindOfClass:[UITableViewCell class]];
//    NSLog(@"%@", test ? @"true" : @"false");
//    
//    NSLog(@"%@",[NSString stringWithUTF8String:object_getClassName([[[btn superview] superview] superview])]);
    
    NSIndexPath *path = [_tableView indexPathForCell:cell];
    
    LocalSubViewController *sub = [[[LocalSubViewController alloc]
                                     initWithNibName:NSStringFromClass([LocalSubViewController class])
                                     bundle:nil] autorelease];
    sub.con = self;
    
    index = [path row];
    self.selectIndex = path;
    
    self.tableView.scrollEnabled = NO;
    UIFolderTableView *folderTableView = (UIFolderTableView *)_tableView;
    
//    NSLog(@"position: %f , height: %f", sub..position.y, cell.frame.size.height);
    
    [folderTableView openFolderAtIndexPath:path WithContentView:sub.view
                                 openBlock:^(UIView *subClassView, CFTimeInterval duration, CAMediaTimingFunction *timingFunction){
                                     // opening actions
                                 }
                                closeBlock:^(UIView *subClassView, CFTimeInterval duration, CAMediaTimingFunction *timingFunction){
                                    // closing actions
                                }
                           completionBlock:^{
                               // completed actions
                               self.tableView.scrollEnabled = YES;
                           }];

}

- (void) showVideo :(NSInteger) i{
    NSString *localPlayUrl = [NSString stringWithFormat:@"http://127.0.0.1:12345/%@/playlist.m3u8",[[self.downloadedVideos objectAtIndex:i] objectForKey:@"_m3u8UrlMd5"]];
    
    VideoPlayerVieoController *playView = [[VideoPlayerVieoController alloc] initWithContentURL:[NSURL URLWithString:localPlayUrl]];
    [self presentMoviePlayerViewControllerAnimated:playView];
    [playView release];
    playView = nil;
}

//弹出层-播放
- (void) playAction:(UIButton *)btn {
    [self showVideo:index];
}

//弹出层-删除
- (void) delAction:(UIButton *)btn {
    UIFolderTableView *folderTableView = (UIFolderTableView *)_tableView;
    [folderTableView performClose:nil];
    [self delVideo:self.selectIndex];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];//选中后的反显颜色即刻消失
    
    NSInteger row = [indexPath row];
    [self showVideo:row];
}


@end
