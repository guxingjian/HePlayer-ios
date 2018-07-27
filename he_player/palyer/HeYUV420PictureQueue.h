//
//  HeYUV420PictureQueue.h
//  he_player
//
//  Created by qingzhao on 2018/7/18.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "libavformat/avformat.h"

typedef struct yuv420_picture{
    unsigned char* y;
    unsigned char* u;
    unsigned char* v;
    struct yuv420_picture* next;
    double pts;
    int nBytes;
}yuv420_picture;

@interface HeYUV420PictureQueue : NSObject

@property(nonatomic, assign)NSInteger maxBytes;
@property(nonatomic, assign)int nBytes;

+ (instancetype)pictureQueueWithStorageSize:(CGSize)size;
- (void)addPictureWithFrame:(AVFrame*)frame;
- (yuv420_picture*)getPicture;
- (void)freePicture:(yuv420_picture*)pic;

- (void)clear;

@end
