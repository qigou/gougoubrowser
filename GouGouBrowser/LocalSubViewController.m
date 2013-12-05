//
//  LocalSubViewController.m
//  GouGouBrowser
//
//  Created by jia on 13-7-10.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "LocalSubViewController.h"

@interface LocalSubViewController ()

@end

@implementation LocalSubViewController

@synthesize con, playBtn, delBtn;

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
    
    [playBtn addTarget:self.con action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    [delBtn addTarget:self.con action:@selector(delAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [playBtn release];
    [delBtn release];
    [super dealloc];
}
@end
