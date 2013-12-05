//
//  AddBookMarkController.m
//  GouGouBrowser
//
//  Created by jia on 13-7-13.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "AddBookMarkController.h"

@interface AddBookMarkController () {
    BOOL hasTitle,hasUrl, _isAdd;
    NSInteger c_index;
}

@end

@implementation AddBookMarkController

@synthesize navigation_bar, navigationItem, saveButtonItem, navigationTitle, editDic;

- (id) initWithIsAdd:(BOOL) isAdd withDic : (NSMutableDictionary *) dic withIndex : (NSInteger) index {
    self = [super init];
    if(!isAdd) {
        _isAdd = isAdd;
        editDic = dic;
        c_index = index;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    hasTitle = NO,hasUrl = NO;
    
    navigationItem = [[UINavigationItem alloc] init];
    
    UIColor *color = [UIColor colorWithRed:73/255.0 green:78/255.0 blue:90/255.0 alpha:1.0];
    
    UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    titleView.text = navigationTitle;
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
    [btn_close addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btn_close];
    
    navigationItem.leftBarButtonItem = closeButtonItem;
    navigation_bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIButton *btn_save = [[UIButton alloc] initWithFrame:CGRectMake(0,0,50,30)];
    [btn_save setTitle:@"保 存" forState:UIControlStateNormal];
    [btn_save setBackgroundImage:stretchableImage forState:UIControlStateNormal];
    [[btn_save titleLabel] setFont:textfont];
    [[btn_save titleLabel] setTextColor:[UIColor whiteColor]];
    [btn_save addTarget:self action:@selector(editBookMark) forControlEvents:UIControlEventTouchUpInside];
    
    saveButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btn_save];
    saveButtonItem.enabled = NO;
    navigationItem.rightBarButtonItem = saveButtonItem;
    
    [navigation_bar setItems:[NSArray arrayWithObject:navigationItem]];
    
    //input set
    insets = UIEdgeInsetsMake(0, 4, 0, 4);
    UIImage *input_back = [UIImage imageNamed:@"inputBack"];
    input_back = [input_back resizableImageWithCapInsets:insets];
    _imgView = [[UIImageView alloc] initWithImage:input_back];
    
    //解决view里面的控件无法获取焦点
    _imgView.userInteractionEnabled = YES;
    
    [_imgView setFrame:CGRectMake(20, 70, 280, 89)];
    
    _input_title = [[MyTextField alloc] initWithFrame:CGRectMake(10,15,260,30)];
    [_input_title setFont:textfont];
    [_input_title setPlaceholder:@"标题"];
    [_input_title setClearButtonMode:UITextFieldViewModeWhileEditing];
    [_input_title setReturnKeyType:UIReturnKeyDone];
    [_input_title setDelegate:self];
    
    _input_url = [[MyTextField alloc] initWithFrame:CGRectMake(10,60,260,30)];
    [_input_url setFont:textfont];
    [_input_url setPlaceholder:@"URL"];
    [_input_url setClearButtonMode:UITextFieldViewModeWhileEditing];
    [_input_url setKeyboardType:UIKeyboardTypeURL];
    [_input_url setReturnKeyType:UIReturnKeyDone];
    [_input_url setDelegate:self];
    
    [_input_title becomeFirstResponder];
    
    if(!_isAdd) {
        _input_title.text = [editDic objectForKey:@"title"];
        _input_url.text = [editDic objectForKey:@"url"];
        
        hasUrl = YES;
        hasTitle = YES;
        saveButtonItem.enabled = YES;
    }
    
    [_imgView addSubview:_input_title];
    [_imgView addSubview:_input_url];
    
    [[self view] addSubview:_imgView];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSMutableString *value = NULL;
    
    if(textField == _input_title) {
        value = [[_input_title.text mutableCopy] autorelease];
        [value replaceCharactersInRange:range withString:string];
        hasTitle = [value length] != 0;
    }
    if(textField == _input_url) {
        value = [[_input_url.text mutableCopy] autorelease];
        [value replaceCharactersInRange:range withString:string];
        hasUrl = [value length] != 0;
    }
    
    if(hasTitle && hasUrl){
        saveButtonItem.enabled = YES;
    } else {
        saveButtonItem.enabled = NO;
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField{
    saveButtonItem.enabled = NO;
    return YES;
}

- (void) editBookMark {
    [editDic setObject:_input_title.text forKey:@"title"];
    
    NSString *url = _input_url.text;
    if(![url hasPrefix:@"http://"]){
        url = [@"http://" stringByAppendingString:url];
    }
    
    [editDic setObject:url forKey:@"url"];
    [editDic setObject:[url md5] forKey:@"urlMD5"];
    
    AppDelegate *myapp = (AppDelegate *)[[UIApplication sharedApplication] delegate] ;
    [myapp editBookMark:editDic withIndex:c_index];
//    [myapp addBookMark:editDic];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"editFinish" object:self userInfo:nil];
    
    [self dismiss];
}

- (void) dismiss {
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.type = kCATransitionReveal;
    animation.duration = 0.7;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.subtype = kCATransitionFromRight;
    [self.view.window.layer addAnimation:animation forKey:nil];
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [navigation_bar release];
    [super dealloc];
}
@end
