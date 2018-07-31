//
//  HeMediaAnalyser.h
//  he_player
//
//  Created by qingzhao on 2018/7/12.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "frame.h"
#import "HeYUV420PictureQueue.h"

@class HeMediaAnalyser;

@protocol HeMediaAnalyserDelegate<NSObject>

- (void)mediaAnalyser:(HeMediaAnalyser*)analyser decodeVideo:(yuv420_picture*)picture frameSize:(CGSize)size;
- (void)mediaAnalyser:(HeMediaAnalyser*)analyser getVideoDuration:(CGFloat)duration;
- (void)mediaAnalyser:(HeMediaAnalyser*)analyser didFinished:(BOOL)finished error:(NSError*)error;

@end

@interface HeMediaAnalyser : NSObject

@property(nonatomic, weak)id<HeMediaAnalyserDelegate> delegate;
@property(nonatomic, assign)BOOL bCanPlay;

- (instancetype)initWithMediaPath:(NSString *)path delegate:(id<HeMediaAnalyserDelegate>)delegate;
- (void)startAnalyse;
- (void)pause;
- (void)clear;
- (void)seekForward;
- (void)seekBackward;
- (void)setTimeStamp:(double)timestamp;

@end
