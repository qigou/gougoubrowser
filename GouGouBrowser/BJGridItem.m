//
//  BJGridItem.m
//  ZakerLike
//
//  Created by bupo Jung on 12-5-15.
//  Copyright (c) 2012年 Wuxi Smart Sencing Star. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BJGridItem.h"

@implementation BJGridItem
@synthesize isEditing,isRemovable,index;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id) initWithTitle:(NSString *)title withUiImage:(UIImage *)uiImage withImage:(NSString *) image_name atIndex:(NSInteger)aIndex editable:(BOOL)removable {
    self = [super initWithFrame:CGRectMake(0, 0, 72, 72)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        normalImage = uiImage;
        titleText = title;
        self.isEditing = NO;
        index = aIndex;
        self.isRemovable = removable;
        
        // place a clickable button on top of everything
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [_button setFrame:self.bounds];
        [_button setBackgroundImage:normalImage forState:UIControlStateNormal];
        [_button setBackgroundColor:[UIColor clearColor]];
        
        //边框
        _button.layer.masksToBounds=YES;
        _button.layer.cornerRadius=5;
        
        if(NULL != image_name){
            [_button setImage:[UIImage imageNamed:image_name] forState:UIControlStateNormal];
        }
        
        [_button addTarget:self action:@selector(clickItem:) forControlEvents:UIControlEventTouchUpInside];
        
        //label
        _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 75, 72, 29)];
        [_label setText:titleText];
        [_label setFont:[UIFont systemFontOfSize: 12.0]];
        UIColor *title_color = [UIColor colorWithRed:135/255.0 green:135/255.0 blue:135/255.0 alpha:1.0];
        [_label setTextColor:title_color];
        //文字居中显示
        _label.textAlignment = NSTextAlignmentCenter;
        //自动折行设置
        _label.lineBreakMode = NSLineBreakByTruncatingTail;
        _label.numberOfLines = 0;
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressedLong:)];
        [self addGestureRecognizer:longPress];
        longPress = nil;
        
        [self addSubview:_button];
        [self addSubview:_label];
        
        if (self.isRemovable) {
            // place a remove button on top right corner for removing item from the board
            deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            float w = 20;
            float h = 20;
            
            [deleteButton setFrame:CGRectMake(self.frame.origin.x,self.frame.origin.y, w, h)];
            [deleteButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
            deleteButton.backgroundColor = [UIColor clearColor];
            [deleteButton addTarget:self action:@selector(removeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [deleteButton setHidden:YES];
            [self addSubview:deleteButton];
        }
    }
    return self;
}

- (void) reloadBackgound : (UIImage *)uiImage{
    [[self loadingImage] removeFromSuperview];
    [[self button] setBackgroundImage:uiImage forState:UIControlStateNormal];
}

//drawing
//- (void)drawRect:(CGRect)rect{
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGMutablePathRef path = CGPathCreateMutable();

//    CGPathAddRect(path, nil, self.bounds);
//    CGContextAddPath(context, path);
//    //[[UIColor colorWithWhite:1.0f alpha:0.0f]setFill];
//    [[UIColor colorWithWhite:1 alpha:1.0f] setStroke];
//    CGContextSetLineWidth(context, 5.0f);
//    CGContextDrawPath(context, kCGPathStroke);
//    float radius = 15;
//    float w = self.bounds.size.width;
//    float h = self.bounds.size.height;
//    float x = self.bounds.origin.x;
//    float y = self.bounds.origin.y;
//
//    CGPathMoveToPoint(path, NULL, x, y + radius);
//    CGPathAddArcToPoint(path, NULL,x, y, x, y + radius, radius);
//    CGPathAddArcToPoint(path, NULL, x + w, y, x + w, y + radius, radius);
//    CGPathAddArcToPoint(path, NULL, x + w, y + h, x + w - radius, y + h, radius);
//    CGPathAddArcToPoint(path, NULL, x, y + h, x, y + h - radius, radius);
//
//    CGPathCloseSubpath(path);
//    CGContextAddPath(context, path);
//    CGContextSetLineWidth(context, 15.0f);
//    [[UIColor colorWithWhite:1 alpha:1.0f] setStroke];
//    CGContextStrokePath(context);
//    CGPathRelease(path);
//}
#pragma mark - UI actions

- (void) clickItem:(id)sender {
    [_delegate gridItemDidClicked:self];
}
- (void) pressedLong:(UILongPressGestureRecognizer *) gestureRecognizer{
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            point = [gestureRecognizer locationInView:self];
            [_delegate gridItemDidEnterEditingMode:self];
            //放大这个item
            [self setAlpha:1.0];
            NSLog(@"press long began");
            break;
        case UIGestureRecognizerStateEnded:
            point = [gestureRecognizer locationInView:self];
            [_delegate gridItemDidEndMoved:self withLocation:point moveGestureRecognizer:gestureRecognizer];
            //变回原来大小
            [self setAlpha:1.0];
            NSLog(@"press long ended");
            break;
        case UIGestureRecognizerStateFailed:
            NSLog(@"press long failed");
            break;
        case UIGestureRecognizerStateChanged:
            //移动
            [_delegate gridItemDidMoved:self withLocation:point moveGestureRecognizer:gestureRecognizer];
            NSLog(@"press long changed");
            break;
        default:
            NSLog(@"press long else");
            break;
    }
    
    //CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform"];
    
}

- (void) removeButtonClicked:(id) sender  {
    [_delegate gridItemDidDeleted:self atIndex:index];
}

#pragma mark - Custom Methods

- (void) enableEditing {
    
    if (self.isEditing == YES)
        return;
    
    // put item in editing mode
    self.isEditing = YES;
    
    // make the remove button visible
    [deleteButton setHidden:NO];
    [_button setEnabled:NO];
    // start the wiggling animation
    CGFloat rotation = 0.03;
    
    CABasicAnimation *shake = [CABasicAnimation animationWithKeyPath:@"transform"];
    shake.duration = 0.13;
    shake.autoreverses = YES;
    shake.repeatCount  = MAXFLOAT;
    shake.removedOnCompletion = NO;
    shake.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(self.layer.transform,-rotation, 0.0 ,0.0 ,1.0)];
    shake.toValue   = [NSValue valueWithCATransform3D:CATransform3DRotate(self.layer.transform, rotation, 0.0 ,0.0 ,1.0)];
    
    [self.layer addAnimation:shake forKey:@"shakeAnimation"];
    
    // inform the springboard that the menu items are now editable so that the springboard
    // will place a done button on the navigationbar
    //[(SESpringBoard *)self.delegate enableEditingMode];
    
}

- (void) disableEditing {
    [self.layer removeAnimationForKey:@"shakeAnimation"];
    [deleteButton setHidden:YES];
    [_button setEnabled:YES];
    self.isEditing = NO;
}

# pragma mark - Overriding UiView Methods

- (void) removeFromSuperview {
    
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.0;
        [self setFrame:CGRectMake(self.frame.origin.x+50, self.frame.origin.y+50, 0, 0)];
        [deleteButton setFrame:CGRectMake(0, 0, 0, 0)];
    }completion:^(BOOL finished) {
        [super removeFromSuperview];
    }];
}

@end
