//
//  HePlayerView.m
//  he_player
//
//  Created by qingzhao on 2018/7/12.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import "HePlayerView.h"
#import "HePlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface HePlayerView()

@property(nonatomic, strong)HePlayer* player;

@end

@implementation HePlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affec]ts performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame mediaPath:(NSString *)path
{
    if(self = [super initWithFrame:frame])
    {
        [self setupPlayerWithPath:path];
    }
    return self;
}

- (void)setupPlayerWithPath:(NSString*)path
{
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    
    self.player = [[HePlayer alloc] initWithMediaPath:path renderView:self];
}

- (void)setFrame:(CGRect)frame
{
    if(CGRectEqualToRect(frame, self.frame))
        return ;
    
    [super setFrame:frame];
    self.player.renderStorageChanged = YES;
}

- (void)dealloc
{
    self.player = nil;
}

@end
