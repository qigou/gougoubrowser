//
//  VideoPlayerVieoController.h
//  GouGouBrowser
//
//  Created by jia on 13-7-10.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "HTTPServer.h"

@interface VideoPlayerVieoController : MPMoviePlayerViewController

@property (retain, nonatomic) HTTPServer *httpServer;

@end
