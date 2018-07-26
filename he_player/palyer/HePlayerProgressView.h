//
//  HePlayerProgressView.h
//  he_player
//
//  Created by qingzhao on 2018/7/25.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HePlayerProgressViewDelegate<NSObject>

- (void)changeToTime:(CGFloat)timestamp;

@end

@interface HePlayerProgressView : UIView

@property(nonatomic, assign)int64_t nDuration;

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<HePlayerProgressViewDelegate>)delegate;

- (void)changeTimePositionWithTime:(CGFloat)timestamp;
- (void)adjustFrame;

@end
