//
//  VideoPlayerVieoController.m
//  GouGouBrowser
//
//  Created by jia on 13-7-10.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "VideoPlayerVieoController.h"

@interface VideoPlayerVieoController ()

@end

@implementation VideoPlayerVieoController

@synthesize httpServer;

//设置横屏
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIDeviceOrientationIsLandscape(interfaceOrientation);
//    return (YES);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //建立本地http服务
    NSError *error = [[NSError alloc] init ];
    
    httpServer = [[HTTPServer alloc] init];
    
    [httpServer setType:@"_http._tcp."];
    [httpServer setPort:12345];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *webPath = [[paths objectAtIndex:0] stringByAppendingString:@"/http/"];
    
    NSLog(@"%@",webPath);
    [httpServer setDocumentRoot:webPath];
    
    if(![httpServer start:&error])
    {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
    else {
        NSLog(@"Start the http server") ;
    }
    
    self.view.frame = self.view.frame;//全屏播放（全屏播放不可缺）
//    self.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;//全屏播放（全屏播放不可缺）    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieFinishedCallback:)                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    
    [self.moviePlayer play];
}

- (void) movieFinishedCallback:(NSNotification*) aNotification {
    NSLog(@"22222");
//    NSLog(@"finished callback %@" , aNotification) ;
//    if ([[aNotification.userInfo objectForKey:@"MPMoviePlayerPlaybackDidFinishReasonUserInfoKey"] intValue] == 1) {
//    }
    [httpServer stop];
    [httpServer release], httpServer = nil;
}

- (void) viewWillDisappear:(BOOL)animated {
    NSLog(@"11111");
//    if (httpServer.isRunning){
//        [httpServer stop] ;
//        [httpServer release] ;
//    }
}

- (void) dealloc {
    [super dealloc];
    [httpServer release],httpServer = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
