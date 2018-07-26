//
//  HePlayer.h
//  he_player
//
//  Created by qingzhao on 2018/7/12.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HePlayer : NSObject

- (instancetype)initWithMediaPath:(NSString *)path renderView:(UIView*)view;

@property(nonatomic, assign)BOOL playing;
@property(atomic, assign)BOOL renderStorageChanged;

- (void)goFowartWithTimeInterval:(NSTimeInterval)nVal;
- (void)goBackWithTimeInterval:(NSTimeInterval)nVal;

- (void)destroy;

@end
