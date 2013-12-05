//
//  HistoryViewController.m
//  GouGouBrowser
//
//  Created by jia on 13-7-14.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "HistoryViewController.h"

@interface HistoryViewController (){
    NSMutableArray *data_arr;
    BOOL isOpen;
}

@end

@implementation HistoryViewController

@synthesize navigation_bar, navigationItem, selectIndex, table;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    navigationItem = [[UINavigationItem alloc] init];
    
    UIColor *color = [UIColor colorWithRed:73/255.0 green:78/255.0 blue:90/255.0 alpha:1.0];
    
    UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    titleView.text = @"历史纪录";
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
    
    UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btn_close];
    
    navigationItem.leftBarButtonItem = closeButtonItem;
    
    UIButton *btn_save = [[UIButton alloc] initWithFrame:CGRectMake(0,0,50,30)];
    [btn_save setTitle:@"清 空" forState:UIControlStateNormal];
    [btn_save setBackgroundImage:stretchableImage forState:UIControlStateNormal];
    [[btn_save titleLabel] setFont:textfont];
    [[btn_save titleLabel] setTextColor:[UIColor whiteColor]];
    [btn_save addTarget:self action:@selector(clearAll) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *saveButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btn_save];
    navigationItem.rightBarButtonItem = saveButtonItem;
    
    navigation_bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [navigation_bar setItems:[NSArray arrayWithObject:navigationItem]];
    
    [navigationItem release];

    //data setup
    data_arr = [[NSMutableArray alloc] initWithObjects:[[NSMutableDictionary alloc]initWithObjectsAndKeys:@"今天",@"title",nil], [[NSMutableDictionary alloc]initWithObjectsAndKeys:@"昨天",@"title",nil], [[NSMutableDictionary alloc]initWithObjectsAndKeys:@"更早",@"title",nil], nil];
    
    NSInteger count = [data_arr count];
    for (NSUInteger i = 1; i <= count; i++) {
        NSMutableArray *arr = [VideoDownloader selectHistory:i withLimit:-1];
        if([arr count] == 0){
            [arr addObject:[[NSDictionary alloc]initWithObjectsAndKeys:@"暂时没有访问记录",@"title",@"y",@"flag",nil]];
        }
        [[data_arr objectAtIndex:(i-1)] setObject:arr forKey:@"list"];
	}
    
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [data_arr count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (isOpen) {
        if (self.selectIndex.section == section) {
            NSMutableArray *arr = [[data_arr objectAtIndex:section] objectForKey:@"list"];
            return [arr count] + 1;
        }
    }
    return 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (isOpen && self.selectIndex.section == indexPath.section&&indexPath.row!=0) {
        static NSString *CellIdentifier = @"Cell2";
        Cell2 *cell = (Cell2*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (!cell) {
            cell = [[[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil] objectAtIndex:0];
        }
        NSArray *arr = [[data_arr objectAtIndex:indexPath.section] objectForKey:@"list"];
        
        NSString *name = [[arr objectAtIndex:indexPath.row - 1] objectForKey:@"title"];
        cell.l_title.text = name;
        NSString *url = [[arr objectAtIndex:indexPath.row - 1] objectForKey:@"url"];
        cell.l_url.text = url;

        CGRect rect = [cell.l_title frame];

        if([[arr objectAtIndex:indexPath.row - 1] objectForKey:@"flag"]){
            rect.origin.y = 12;
        } else {
            rect.origin.y = 3;
        }
        
        [cell.l_title setFrame:rect];
        return cell;
    } else {
        static NSString *CellIdentifier = @"Cell1";
        Cell1 *cell = (Cell1*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil] objectAtIndex:0];
        }
        NSString *name = [[data_arr objectAtIndex:indexPath.section] objectForKey:@"title"];
        cell.titleLabel.text = name;
        [cell changeArrowWithUp:([self.selectIndex isEqual:indexPath]?YES:NO)];
        UIColor *color = [UIColor colorWithRed:247/255.0 green:247/255.0 blue:247/255.0 alpha:1.0];
        [cell.contentView setBackgroundColor:color];

        return cell;
    }

}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        if ([indexPath isEqual:self.selectIndex]) {
            isOpen = NO;
            [self didSelectCellRowFirstDo:NO nextDo:NO];
            self.selectIndex = nil;
        } else {
            if (!self.selectIndex) {
                self.selectIndex = indexPath;
                [self didSelectCellRowFirstDo:YES nextDo:NO];
            }else {                
                [self didSelectCellRowFirstDo:NO nextDo:YES];
            }
        }
        
    } else {        
        NSMutableArray *arr = [[data_arr objectAtIndex:self.selectIndex.section] objectForKey:@"list"];
        
        NSMutableDictionary *dic = [arr objectAtIndex:(indexPath.row - 1)];
        
        if([arr count] == 1){
            BOOL flag = [[arr objectAtIndex:0] objectForKey:@"flag"] ? NO : YES;
            if(!flag) return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadWeb" object:self userInfo: dic];
        [self dismiss:nil];
        
//        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[dic objectForKey:@"title"] message:nil delegate:nil cancelButtonTitle:@"取消" otherButtonTitles: nil] autorelease];
//        [alert show];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0){
        return NO;
    }
    NSArray *arr = [[data_arr objectAtIndex:indexPath.section] objectForKey:@"list"];
    if([arr count] == 1){
        return [[arr objectAtIndex:0] objectForKey:@"flag"] ? NO : YES;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *arr = [[data_arr objectAtIndex:self.selectIndex.section] objectForKey:@"list"];
        
        NSMutableDictionary *dic = [arr objectAtIndex:(indexPath.row - 1)];
        [VideoDownloader delHistory:NO withUrlMD5:[dic objectForKey:@"urlMd5"]];
        
        [arr removeObjectAtIndex:indexPath.row - 1];
        
        [table deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        if([arr count] == 0){
            [arr addObject:[[NSDictionary alloc]initWithObjectsAndKeys:@"暂时没有访问记录",@"title",@"y",@"flag",nil]];
            [table reloadData];
        }

    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (void)didSelectCellRowFirstDo:(BOOL)firstDoInsert nextDo:(BOOL)nextDoInsert
{
    isOpen = firstDoInsert;
    
    Cell1 *cell = (Cell1 *)[table cellForRowAtIndexPath:self.selectIndex];
    [cell changeArrowWithUp:firstDoInsert];
    
    [table beginUpdates];
    
    int section = self.selectIndex.section;
    NSArray *arr = [[data_arr objectAtIndex:section] objectForKey:@"list"];

    int contentCount = [arr count];
	NSMutableArray* rowToInsert = [[NSMutableArray alloc] init];
	for (NSUInteger i = 1; i < contentCount + 1; i++) {
		NSIndexPath* indexPathToInsert = [NSIndexPath indexPathForRow:i inSection:section];
		[rowToInsert addObject:indexPathToInsert];
	}
	
	if (firstDoInsert){
        [table insertRowsAtIndexPaths:rowToInsert withRowAnimation:UITableViewRowAnimationTop];
    }
	else {
        [table deleteRowsAtIndexPaths:rowToInsert withRowAnimation:UITableViewRowAnimationTop];
    }
    
	[rowToInsert release];
	
	[table endUpdates];
    if (nextDoInsert) {
        isOpen = YES;
        self.selectIndex = [table indexPathForSelectedRow];
        [self didSelectCellRowFirstDo:YES nextDo:NO];
    }
    if (isOpen)
        [table scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - UIActionSheetDelegate
-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(0 == buttonIndex){
        [VideoDownloader delHistory:YES withUrlMD5:NULL];

        [self tableView:table didSelectRowAtIndexPath:self.selectIndex];
//        [table selectRowAtIndexPath:selectIndex animated:YES scrollPosition:UITableViewScrollPositionTop];
        
        //重新设置数组
        NSInteger count = [data_arr count];
        for (NSUInteger i = 1; i <= count; i++) {
            NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
            [arr addObject:[[NSDictionary alloc]initWithObjectsAndKeys:@"暂时没有访问记录",@"title",@"y",@"flag",nil]];
            [[data_arr objectAtIndex:(i-1)] setObject:arr forKey:@"list"];
        }

        [table reloadData];
    }
}

- (void) clearAll {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:@"取消"
                                  destructiveButtonTitle:@"清空历史记录"
                                  otherButtonTitles:nil,nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [actionSheet showInView:self.view];
}

- (void)dismiss:(id)sender
{
    //通知首页刷新listdata
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reload_data" object:self userInfo:nil];
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
    [super dealloc];
}
@end
