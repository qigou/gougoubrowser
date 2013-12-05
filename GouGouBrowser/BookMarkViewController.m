
//  BookMarkViewController.m
//  GouGouBrowser
//
//  Created by jia on 13-7-13.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "BookMarkViewController.h"

#define l_title 1
#define l_url 2

@interface BookMarkViewController (){
    BOOL isEdit;
}

@end

@implementation BookMarkViewController

@synthesize navigation_bar, navigationItem, table, data_arr, saveButtonItem;

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
    titleView.text = @"书签";
    [titleView setBackgroundColor:[UIColor clearColor]];
    [titleView setFont:[UIFont systemFontOfSize: 16.0]];
    titleView.textAlignment = NSTextAlignmentCenter;
    [titleView setTextColor: color];
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
    
    UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btn_close];
    
    navigationItem.leftBarButtonItem = closeButtonItem;
    
    UIButton *btn_save = [[UIButton alloc] initWithFrame:CGRectMake(0,0,50,30)];
    [btn_save setTitle:@"编 辑" forState:UIControlStateNormal];
    [btn_save setBackgroundImage:stretchableImage forState:UIControlStateNormal];
    [[btn_save titleLabel] setFont:textfont];
    [[btn_save titleLabel] setTextColor:[UIColor whiteColor]];
    [btn_save addTarget:self action:@selector(editing) forControlEvents:UIControlEventTouchUpInside];
    
    saveButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btn_save];
    navigationItem.rightBarButtonItem = saveButtonItem;
    
    navigation_bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [navigation_bar setItems:[NSArray arrayWithObject:navigationItem]];
    
    //注册通知
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(editFinish:)
               name:@"editFinish"
             object:nil];
    
    table.allowsSelectionDuringEditing = YES;
    
    //data setup
    [self getPlistData];
}

- (void) editing {
    UIButton *btn_save = (UIButton *) saveButtonItem.customView;
    if(isEdit) {
        [btn_save setTitle:@"编 辑" forState:UIControlStateNormal];
        isEdit = NO;
    } else {
        [btn_save setTitle:@"完 成" forState:UIControlStateNormal];
        isEdit = YES;
    }
    
    [table setEditing:isEdit animated:YES];
}

- (void) getPlistData {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"bookmark.plist"];
    data_arr = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
}

- (void) editFinish :(NSNotification*)sender {
    [self getPlistData];
    [table reloadData];
}

#pragma mark - Table view data source
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [data_arr count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *TableSampleIdentifier = @"BookmarkCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TableSampleIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"BookmarkCell" owner:self options:nil];
        if ([nib count] > 0) {
            cell = self.bookmark_cell;
        } else {
            NSLog(@"failed to load CustomCell nib file!");
        }
    }
    
    NSInteger row = [indexPath row] ;
    
    UILabel *book_title = (UILabel *)[cell viewWithTag:l_title];
    book_title.text = [[self.data_arr objectAtIndex:row] objectForKey:@"title"];
    
    UILabel *book_url = (UILabel *) [cell viewWithTag:l_url];
    book_url.text = [[self.data_arr objectAtIndex:row] objectForKey:@"url"];
    
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

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [data_arr removeObjectAtIndex:[indexPath row]];
        [table deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
        [myapp delBookMark:[indexPath row] withUrlMD5:nil];
    }
    
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *dic = [data_arr objectAtIndex:[indexPath row]];
    if(isEdit) {
        CATransition *animation = [CATransition animation];
        animation.delegate = self;
        animation.type = kCATransitionReveal;
        animation.duration = 0.7;
        animation.timingFunction = UIViewAnimationCurveEaseInOut;
        
        AddBookMarkController *controller = [[AddBookMarkController alloc] initWithIsAdd:NO withDic:dic withIndex:[indexPath row]];
        controller.navigationTitle = @"编辑书签";
        [self.view.window.layer addAnimation:animation forKey:nil];
        [self presentViewController:controller animated:NO completion:nil];
    } else {
        [self dismiss:nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadWeb" object:self userInfo:[data_arr objectAtIndex:[indexPath row]]];
    }
}

- (void)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [navigation_bar release];
    [table release];
    [navigationItem release];
    [_bookmark_cell release];
    [saveButtonItem release];
    [super dealloc];
}
@end
