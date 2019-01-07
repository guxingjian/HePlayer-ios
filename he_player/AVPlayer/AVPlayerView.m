//
//  AVPlayerView.m
//  he_player
//
//  Created by qingzhao on 2018/7/31.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import "AVPlayerView.h"

#import <AVFoundation/AVFoundation.h>

@interface AVPlayerView()

@property(nonatomic, strong)id strUrl;
@property(nonatomic, strong)AVPlayer* player;

@end

@implementation AVPlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame mediaPath:(id)strUrl
{
    if(self = [super initWithFrame:frame])
    {
        self.strUrl = strUrl;
        [self setupAudioSession];
        [self setUpPlayer];
    }
    return self;
}

- (void)setupAudioSession
{
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
}

- (void)setUpPlayer
{
    AVURLAsset* asset = nil;
    if([self.strUrl isKindOfClass:[NSURL class]])
    {
        asset = [[AVURLAsset alloc] initWithURL:self.strUrl options:nil];
    }
    else
    {
        asset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:self.strUrl] options:nil];
    }
    AVPlayerItem* item = [[AVPlayerItem alloc] initWithAsset:asset];
    AVPlayer* player = [[AVPlayer alloc] initWithPlayerItem:item];
    player.automaticallyWaitsToMinimizeStalling = NO;
    self.player = player;
    AVPlayerLayer* playLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playLayer.frame = self.bounds;
    [self.layer addSublayer:playLayer];
    [player play];
}

@end
