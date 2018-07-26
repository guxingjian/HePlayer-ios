//
//  HeYUV420PictureQueue.m
//  he_player
//
//  Created by qingzhao on 2018/7/18.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import "HeYUV420PictureQueue.h"

@implementation HeYUV420PictureQueue
{
    int _nW;
    int _nH;
    yuv420_picture* _head_pic;
    yuv420_picture* _tail_pic;
    int _picCount;
    int _nBytes;
    NSCondition* _condition;
}

+ (instancetype)pictureQueueWithStorageSize:(CGSize)size
{
    HeYUV420PictureQueue* queue = [[HeYUV420PictureQueue alloc] initWithStorageSize:size];
    return queue;
}

- (instancetype)initWithStorageSize:(CGSize)size
{
    if(self = [super init])
    {
        _nW = size.width;
        _nH = size.height;
        _condition = [[NSCondition alloc] init];
        self.maxBytes = 1024*1024*15;
    }
    return self;
}

- (void)addPictureWithFrame:(AVFrame *)frame
{
    [_condition lock];
    while(_nBytes >= self.maxBytes)
    {
        [_condition wait];
    }
    
    int nBytes = _nW*_nH;
    yuv420_picture* pic = av_mallocz(sizeof(yuv420_picture));
    unsigned char* y = av_mallocz(nBytes);
    memcpy(y, frame->data[0], nBytes);
    
    unsigned char* u = av_mallocz(nBytes/4);
    memcpy(u, frame->data[1], nBytes/4);
    
    unsigned char* v = av_mallocz(nBytes/4);
    memcpy(v, frame->data[2], nBytes/4);
    pic->y = y;
    pic->u = u;
    pic->v = v;
    pic->pts = frame->pts;
    pic->nBytes = (int)1.5*nBytes;
    if(!_head_pic)
    {
        _head_pic = pic;
    }
    else
    {
        _tail_pic->next = pic;
    }
    _tail_pic = pic;
    
    _picCount ++;
    _nBytes += (int)1.5*nBytes;
    
    [_condition signal];
    [_condition unlock];
}

- (yuv420_picture*)getPicture
{
    yuv420_picture* pic = 0;
    [_condition lock];
    while(_picCount == 0)
    {
        [_condition wait];
    }
    
    pic = _head_pic;
    _head_pic = _head_pic->next;
    _picCount --;
    int nBytes = _nW*_nH;
    _nBytes -= (int)1.5*nBytes;
    if(0 == _picCount)
    {
        _tail_pic = 0;
        _nBytes = 0;
    }
    
    [_condition signal];
    [_condition unlock];
    
    return pic;
}

- (void)freePicture:(yuv420_picture *)pic
{
    if(!pic)
        return ;
    
    av_free(pic->y);
    av_free(pic->u);
    av_free(pic->v);
}

- (void)clear
{
    [_condition lock];
    
    yuv420_picture* pic = 0;
    while(_head_pic)
    {
        pic = _head_pic;
        _head_pic = _head_pic->next;
        [self freePicture:pic];
    }
    
    _head_pic = nil;
    _tail_pic = nil;
    _picCount = 0;
    _nBytes = 0;
    
    [_condition signal];
    [_condition unlock];
}

@end
