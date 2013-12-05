//
//  MyTextField.m
//  GouGouBrowser
//
//  Created by jia on 13-6-23.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "MyTextField.h"

@implementation MyTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (CGRect)clearButtonRectForBounds:(CGRect)bounds{
    return CGRectMake(240,0,15,15);
}

@end
