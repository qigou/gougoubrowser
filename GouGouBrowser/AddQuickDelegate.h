//
//  AddQuickDelegate.h
//  GouGouBrowser
//
//  Created by jia on 13-6-24.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AddQuickDelegate <NSObject>

- (void)addQuick:(NSString *)title needUrl :(NSString *) url;

@end
