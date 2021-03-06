//
//  HeYUV420PictureQueue.h
//  he_player
//
//  Created by qingzhao on 2018/7/18.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "libavformat/avformat.h"
#import "HEDataQeueuProtocol.h"

typedef struct yuv420_picture{
    unsigned char* y;
    int y_len;
    unsigned char* u;
    int u_len;
    unsigned char* v;
    int v_len;
    struct yuv420_picture* next;
    double pts;
    int nBytes;
}yuv420_picture;

@interface HeYUV420PictureQueue : NSObject

@property(nonatomic, assign)NSInteger maxBytes;
@property(nonatomic, assign)int nCacheCount;
@property(atomic, assign)BOOL bShouldCache;
@property(nonatomic, weak)id<HeDataQueueDelegate> delegate;
@property(atomic, assign)BOOL stop;

+ (instancetype)pictureQueueWithStorageSize:(CGSize)size delegate:(id<HeDataQueueDelegate>)delegate;
- (void)addPictureWithFrame:(AVFrame*)frame;
- (yuv420_picture*)getPicture;
- (void)freePicture:(yuv420_picture*)pic;

- (void)clear;

@end
