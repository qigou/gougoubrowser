//
//  Cell2.m
//  GouGouBrowser
//
//  Created by jia on 13-7-14.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import "Cell2.h"

@interface Cell2 ()

@end

@implementation Cell2

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)dealloc {
    [_l_title release];
    [_l_url release];
    [super dealloc];
}
@end
