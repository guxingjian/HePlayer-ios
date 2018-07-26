//
//  HeVideoState.m
//  he_player
//
//  Created by qingzhao on 2018/7/13.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import "HeAudioDataQueue.h"

@interface HeAudioDataQueue()

@property(nonatomic, readwrite)NSCondition* condition;
@property(nonatomic, assign)NSInteger nSize;

@end

@implementation HeAudioDataQueue
{
    audio_buffer* _head_buf;
    audio_buffer* _tail_buf;
    int _bufCount;
    int _nBytes;
}

- (instancetype)initWithBufferSize:(NSInteger)size
{
    if(self = [super init])
    {
        self.nSize = size;
        self.maxBytes = 1024*100;
    }
    return self;
}

- (NSCondition *)condition
{
    if(!_condition)
    {
        _condition = [[NSCondition alloc] init];
    }
    return _condition;
}

- (void)clear
{
    [self.condition lock];
    
    audio_buffer* buf = 0;
    while(_head_buf)
    {
        buf = _head_buf;
        _head_buf = _head_buf->next;
        [self freeBuffer:buf];
    }
    
    _head_buf = nil;
    _tail_buf = nil;
    _bufCount = 0;
    _nBytes = 0;
    
    [self.condition signal];
    [self.condition unlock];
}

- (audio_buffer *)idleAudioBuffer
{
    audio_buffer* buffer = av_mallocz(sizeof(audio_buffer));
    buffer->buffer = av_mallocz(self.nSize);
    buffer->size = self.nSize;
    return buffer;
}

- (void)putBuffer:(audio_buffer *)buffer
{
    [_condition lock];
    while(_nBytes >= self.maxBytes)
    {
        [_condition wait];
    }
    
    if(!_head_buf)
    {
        _head_buf = buffer;
    }
    else
    {
        _tail_buf->next = buffer;
    }
    _tail_buf = buffer;
    _bufCount ++;
    _nBytes += buffer->size;
    
    [_condition signal];
    [_condition unlock];
}

- (audio_buffer *)getBuffer
{
    [_condition lock];
    while(_bufCount == 0)
    {
        [_condition wait];
    }
    
    audio_buffer* head = _head_buf;
    _head_buf = head->next;
    _bufCount --;
    _nBytes -= head->size;
    if(0 == _bufCount)
    {
        _tail_buf = 0;
        _nBytes = 0;
    }
    
    [_condition signal];
    [_condition unlock];
    return head;
}

- (void)freeBuffer:(audio_buffer *)buffer
{
    if(!buffer)
        return ;
    
    av_free(buffer->buffer);
    av_free(buffer);
}

@end