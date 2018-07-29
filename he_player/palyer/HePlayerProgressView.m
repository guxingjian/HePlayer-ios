//
//  HePlayerProgressView.m
//  he_player
//
//  Created by qingzhao on 2018/7/25.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import "HePlayerProgressView.h"

@interface HePlayerProgressView()

@property(nonatomic, strong)CALayer* posLayer;
@property(nonatomic, strong)CALayer* lineLayer;
@property(nonatomic, assign)BOOL bMoveFlag;
@property(nonatomic, assign)BOOL bTapFlag;
@property(nonatomic, weak)id<HePlayerProgressViewDelegate> delegate;
@property(nonatomic, assign)CGFloat currentTimeStamp;

@end

@implementation HePlayerProgressView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<HePlayerProgressViewDelegate>)delegate
{
    if(self = [super initWithFrame:frame])
    {
        self.delegate = delegate;
        [self buildInterface];
    }
    return self;
}

- (void)buildInterface
{
    CALayer* lineLayer = [CALayer layer];
    lineLayer.frame = CGRectMake(10, self.bounds.size.height/2 - 6/2, self.bounds.size.width - 10*2, 6);
    lineLayer.backgroundColor = [UIColor greenColor].CGColor;
    [self.layer addSublayer:lineLayer];
    self.lineLayer = lineLayer;
    
    CALayer* posLayer = [CALayer layer];
    posLayer.frame = CGRectMake(10 - 8/2, self.bounds.size.height/2 - 8/2, 8, 8);
    posLayer.backgroundColor = [UIColor blueColor].CGColor;
    posLayer.cornerRadius = 4;
    posLayer.masksToBounds = YES;
    [self.layer addSublayer:posLayer];
    self.posLayer = posLayer;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch* touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self];
    if(CGRectContainsPoint(self.posLayer.frame, pt))
    {
        self.bMoveFlag = YES;
    }
    else if(CGRectContainsPoint(self.lineLayer.frame, pt))
    {
        self.bTapFlag = YES;
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if(!self.bMoveFlag)
        return ;
    
    UITouch* touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self];
    if(pt.x < self.lineLayer.frame.origin.x)
    {
        pt.x = self.lineLayer.frame.origin.x;
    }
    if(pt.x > self.lineLayer.frame.origin.x + self.lineLayer.frame.size.width)
    {
        pt.x = self.lineLayer.frame.origin.x + self.lineLayer.frame.size.width;
    }
    
    self.posLayer.frame = CGRectMake(pt.x - 4, self.bounds.size.height/2 - 8/2, 8, 8);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    UITouch* touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self];
    CGFloat fTime = (pt.x - self.lineLayer.frame.origin.x)/self.lineLayer.frame.size.width*self.nDuration;
    
    if(self.bMoveFlag)
    {
        self.bMoveFlag = NO;
        if([self.delegate respondsToSelector:@selector(changeToTime:)])
        {
            [self.delegate changeToTime:fTime];
        }
    }
    else if(self.bTapFlag)
    {
        self.bTapFlag = NO;
        if([self.delegate respondsToSelector:@selector(changeToTime:)])
        {
            [self.delegate changeToTime:fTime];
        }
    }
}

- (void)changeTimePositionWithTime:(CGFloat)timestamp
{
    if(self.bMoveFlag || self.bTapFlag)
    {
        return ;
    }
    
    if(self.nDuration <= 0)
        return ;
    
    self.currentTimeStamp = timestamp;
    CGFloat fPos = timestamp/self.nDuration*self.lineLayer.frame.size.width;
    
    [CATransaction begin];
    [CATransaction disableActions];
    self.posLayer.frame = CGRectMake(self.lineLayer.frame.origin.x + fPos - 4, self.bounds.size.height/2 - 8/2, 8, 8);
    [CATransaction commit];
}

- (void)adjustFrame
{
    CGRect rtSuper = self.superview.frame;
    
    self.frame = CGRectMake(0, rtSuper.size.height - 50, rtSuper.size.width, 20);
    self.lineLayer.frame = CGRectMake(10, self.bounds.size.height/2 - 6/2, self.bounds.size.width - 10*2, 6);
    [self changeTimePositionWithTime:self.currentTimeStamp];
}

@end
