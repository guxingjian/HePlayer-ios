//
//  HeVideoState.h
//  he_player
//
//  Created by qingzhao on 2018/7/13.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libavformat/avformat.h"
#import "HEDataQeueuProtocol.h"

typedef struct audio_buffer{
    uint8_t* buffer;
    NSInteger size;
    double pts;
    struct audio_buffer* next;
}audio_buffer;

@interface HeAudioDataQueue : NSObject

@property(nonatomic, assign)int maxBytes;
@property(nonatomic, assign)int nCacheBytes;
@property(atomic, assign)BOOL bShouldCache;
@property(nonatomic, weak)id<HeDataQueueDelegate> delegate;

- (instancetype)initWithBufferSize:(NSInteger)size delegate:(id<HeDataQueueDelegate>)delegate;

- (audio_buffer*)idleAudioBuffer;
- (void)putBuffer:(audio_buffer*)buffer;
- (audio_buffer*)getBuffer;
- (void)freeBuffer:(audio_buffer*)buffer;

- (void)clear;

@end
