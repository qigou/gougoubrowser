//
//  Cell1.h
//  GouGouBrowser
//
//  Created by jia on 13-7-14.
//  Copyright (c) 2013年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Cell1 : UITableViewCell

- (void)changeArrowWithUp:(BOOL)up;

@property (retain, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;

@end
