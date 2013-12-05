//
//  Cell1.m
//  GouGouBrowser
//
//  Created by jia on 13-7-14.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "Cell1.h"

@interface Cell1 ()

@end

@implementation Cell1

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)changeArrowWithUp:(BOOL)up
{
    if (up) {
        self.arrowImageView.image = [UIImage imageNamed:@"UpAccessory"];
    } else {
        self.arrowImageView.image = [UIImage imageNamed:@"DownAccessory"];
    }
}

- (void)dealloc {
    [_arrowImageView release];
    [_titleLabel release];
    [super dealloc];
}
@end
