//
//  VideoDownloadDelegate.h
//  GouGouBrowser
//
//  Created by jia on 13-7-7.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VideoDownloadDelegate <NSObject>

@optional

- (void)addDownloadFinished;
- (void)addDownloadError:(NSNumber *)ErrorCode;
@end
