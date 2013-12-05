//
//  AddressTextField.m
//  GouGouBrowser
//
//  Created by jia on 13-7-31.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "AddressTextField.h"

@implementation AddressTextField

@synthesize isLong;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

//控制placeHolder的位置
-(CGRect)placeholderRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 8, 0);
}

//控制显示文本的位置
-(CGRect)textRectForBounds:(CGRect)bounds
{
    bounds.size.width -= 47;
    return CGRectInset(bounds, 8, 0);
}

//控制编辑文本的位置
-(CGRect)editingRectForBounds:(CGRect)bounds
{
    bounds.size.width -= 47;
    return CGRectInset( bounds, 8 , 0);
}

//右侧按钮位置
- (CGRect) rightViewRectForBounds:(CGRect)bounds
{
    CGFloat width = isLong ? bounds.size.width-47 : bounds.size.width-27;
    return CGRectMake(width, 8, 15, 15);
}

-(CGRect) clearButtonRectForBounds:(CGRect)bounds
{
    CGFloat width = isLong ? bounds.size.width-47 : bounds.size.width-27;
    return CGRectMake(width, 8, 15, 15);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
