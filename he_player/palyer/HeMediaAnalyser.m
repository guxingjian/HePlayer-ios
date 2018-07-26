//
//  HeMediaAnalyser.m
//  he_player
//
//  Created by qingzhao on 2018/7/12.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import "HeMediaAnalyser.h"
#import "libavcodec/avcodec.h"
#import "libavformat/avformat.h"
#import "libavutil/imgutils.h"
#import "libavutil/avutil.h"
#import "libavutil/time.h"
#import "libswscale/swscale.h"
#import "libswresample/swresample.h"
#import "HeAudioDataQueue.h"

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>

#define BUFFER_COUNT 3
#define SEEK_STEP 5


void HandleOutputBufferCallBack (void *aqData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);

@interface HeMediaAnalyser()

@property(nonatomic, strong)NSString* strPath;
@property(nonatomic, weak)id<HeMediaAnalyserDelegate> delegate;
@property(nonatomic, assign)BOOL bShouldConvert;
@property(nonatomic, assign)BOOL bPause;
@property(nonatomic, assign)BOOL bIsAnalysing;
@property(atomic, assign)double audio_clock;
@property(atomic, assign)BOOL audioClearFlag;
@property(atomic, assign)BOOL pictureClearFlag;
@property(atomic, assign)uint64_t seekTime;

@end

@implementation HeMediaAnalyser
{
@public
    AVFormatContext* _formatContext;
    AVCodecContext* _pVideoCodecCtx;
    AVCodec* _pVideoCodec;
    int _videoStream;
    AVFrame* _pFrame;
    AVFrame* _yuvFrame;
    AVPacket* _videoPkt;
    struct SwsContext* swsContext;
    HeYUV420PictureQueue* _pictureQueue;

    double video_clock;
    double frame_timer;
    double frame_last_delay;
    double frame_last_pts;
    
    AVCodecContext* _pAudioCodecCtx;
    AVCodec* _pAudioCodec;
    AVFrame* _audioFrame;
    int _audioStream;
    AudioQueueRef queueRef;
    AudioQueueBufferRef buffers[BUFFER_COUNT];
    HeAudioDataQueue* _audioBufferQueue;
    SwrContext* swrContext;
    AVPacket* audioPkt;
    dispatch_queue_t _audioDispatchQueue;
}

- (void)dealloc
{
    for(NSInteger i = 0; i < BUFFER_COUNT; ++ i)
    {
        AudioQueueFreeBuffer(queueRef, buffers[i]);
    }
    AudioQueueDispose(queueRef, YES);
    
    avformat_close_input(&_formatContext);
    
    avcodec_close(_pVideoCodecCtx);
    avcodec_free_context(&_pVideoCodecCtx);
    av_frame_free(&_pFrame);
    if(swsContext)
    {
        av_frame_free(&_yuvFrame);
        sws_freeContext(swsContext);
    }
    av_packet_free(&_videoPkt);
    
    avcodec_close(_pAudioCodecCtx);
    avcodec_free_context(&_pAudioCodecCtx);
    swr_free(&swrContext);
    av_frame_free(&_audioFrame);
    av_packet_free(&audioPkt);
}

- (instancetype)initWithMediaPath:(NSString *)path delegate:(id<HeMediaAnalyserDelegate>)delegate
{
    if(self = [super init])
    {
        self.strPath = path;
        self.delegate = delegate;
        [self setupAnalyser];
    }
    return self;
}

- (void)setupAnalyser
{
    av_register_all();
    
    AVFormatContext* pFormatCtx = NULL;
    if(avformat_open_input(&pFormatCtx, [self.strPath UTF8String], NULL, NULL) != 0)
    {
        NSLog(@"open file %@ failed", self.strPath);
        return ;
    }
    if(avformat_find_stream_info(pFormatCtx, 0)<0)
    {
        NSLog(@"find stream info failed");
        return ;
    }
    
    int i;
    int videoStream = -1;
    int audioStream = -1;
    for(i=0; i<pFormatCtx->nb_streams; i++)
    {
        AVCodecParameters *codecpar = pFormatCtx->streams[i]->codecpar;
        if(AVMEDIA_TYPE_VIDEO == codecpar->codec_type)
        {
            videoStream = i;
        }
        else if(AVMEDIA_TYPE_AUDIO == codecpar->codec_type)
        {
            if(-1 == audioStream)
            {
                audioStream = i;
            }
        }
    }
    if(-1 == videoStream)
    {
        NSLog(@"can't find videostream");
        return ;
    }
    if(-1 == audioStream)
    {
        NSLog(@"can't find audioStream");
        return ;
    }
    _formatContext = pFormatCtx;
    _videoStream = videoStream;
    _audioStream = audioStream;
    
    [self setVideoConfig];
    [self setAudioConfig];
    
    [self.delegate mediaAnalyser:self getVideoDuration:pFormatCtx->duration/1000000];
}

- (void)setAudioConfig
{
    AVCodecParameters* audioCodecParam = _formatContext->streams[_audioStream]->codecpar;
    AVCodec * pCodec = avcodec_find_decoder(audioCodecParam->codec_id);
    if(!pCodec) {
        return ;
    }
    
    AVCodecContext* pAudioCodecCtx = avcodec_alloc_context3(pCodec);
    if(!pAudioCodecCtx)
    {
        NSLog(@"avcodec_alloc_context3 failed");
        return ;
    }
    
    if(avcodec_parameters_to_context(pAudioCodecCtx, audioCodecParam) < 0)
    {
        NSLog(@"avcodec_parameters_to_context failed");
        return ;
    }
    
    if(avcodec_open2(pAudioCodecCtx, pCodec, 0) != 0)
    {
        NSLog(@"avcodec_open2 failed");
        return ;
    }
    
    _audioFrame = av_frame_alloc();
    audioPkt = av_packet_alloc();
    _pAudioCodecCtx = pAudioCodecCtx;
    _pAudioCodec = pCodec;

    uint64_t out_channel_layout = AV_CH_LAYOUT_STEREO;//声道格式
    enum AVSampleFormat out_sample_fmt = AV_SAMPLE_FMT_S16;//采样格式
    int out_sample_rate = 48000;//采样率
    
    int out_nb_channels = av_get_channel_layout_nb_channels(out_channel_layout);//根据声道格式返回声道个数
    AudioStreamBasicDescription des;
    des.mSampleRate = out_sample_rate;
    des.mFormatID=kAudioFormatLinearPCM;
    des.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    des.mBitsPerChannel=16;//采样的位数
    des.mChannelsPerFrame=out_nb_channels;//通道数
    des.mBytesPerFrame= (out_nb_channels*des.mBitsPerChannel)/8;
    des.mFramesPerPacket=1;
    des.mBytesPerPacket = des.mFramesPerPacket*des.mBytesPerFrame;
    des.mReserved = 0;
    
    int nBufferSize = av_samples_get_buffer_size(NULL, out_nb_channels, _pAudioCodecCtx->frame_size, out_sample_fmt, 1);
    
    _audioDispatchQueue = dispatch_queue_create("audio queue", NULL);
    void *p = (__bridge void *) self;
    AudioQueueNewOutput(&des, HandleOutputBufferCallBack, p,nil, nil, 0, &queueRef);
    for(int i = 0 ; i < BUFFER_COUNT ; i ++){
        AudioQueueAllocateBuffer(queueRef, nBufferSize, &buffers[i]);
    }
    
    Float32 gain = 1.0;
    AudioQueueSetParameter(queueRef, kAudioQueueParam_Volume, gain);
    _audioBufferQueue = [[HeAudioDataQueue alloc] initWithBufferSize:nBufferSize];
    [self setupSwrContext];
    
}

- (void)setupSwrContext
{
    swrContext = swr_alloc();
    if (swrContext == NULL)
    {
        printf("Could not allocate SwrContext\n");
        return ;
    }
    
    uint64_t out_channel_layout = AV_CH_LAYOUT_STEREO;//声道格式
    enum AVSampleFormat out_sample_fmt = AV_SAMPLE_FMT_S16;//采样格式
    int out_sample_rate = 48000;//采样率
    swr_alloc_set_opts(swrContext, out_channel_layout, out_sample_fmt,out_sample_rate,
                       _pAudioCodecCtx->channel_layout, _pAudioCodecCtx->sample_fmt, _pAudioCodecCtx->sample_rate, 0, NULL);
    if (!swrContext || swr_init(swrContext) < 0) {
        NSLog(@"init swrContext failed");
        return ;
    }
}

- (void)setVideoConfig
{
    AVCodecParameters* videoCodecParam = _formatContext->streams[_videoStream]->codecpar;
    AVCodec * pCodec = avcodec_find_decoder(videoCodecParam->codec_id);
    if (!pCodec)
    {
        NSLog(@"avcodec_find_decoder failed");
        return ;
    }
    
    AVCodecContext* pVideoCodecCtx = avcodec_alloc_context3(pCodec);
    if(!pVideoCodecCtx)
    {
        NSLog(@"avcodec_alloc_context3 failed");
        return ;
    }
    
    if(avcodec_parameters_to_context(pVideoCodecCtx, videoCodecParam) < 0)
    {
        NSLog(@"avcodec_parameters_to_context failed");
        return ;
    }
    
    if(avcodec_open2(pVideoCodecCtx, pCodec, 0) != 0)
    {
        NSLog(@"avcodec_open2 failed");
        return ;
    }
    
    
    _pVideoCodecCtx = pVideoCodecCtx;
    _pVideoCodec = pCodec;
    _pFrame = av_frame_alloc();
    _videoPkt = av_packet_alloc();
    if(_pVideoCodecCtx->pix_fmt != AV_PIX_FMT_YUV420P)
    {
        _yuvFrame = av_frame_alloc();
        
        NSInteger nSize = av_image_get_buffer_size(AV_PIX_FMT_YUV420P, _pVideoCodecCtx->width, _pVideoCodecCtx->height, 1);
        unsigned char* outBuffer = av_malloc(nSize);
        av_image_fill_arrays(_yuvFrame->data, _yuvFrame->linesize, outBuffer, AV_PIX_FMT_YUV420P, _pVideoCodecCtx->width, _pVideoCodecCtx->height, 1);
        
        struct SwsContext* img_convert_ctx = sws_getContext(_pVideoCodecCtx->width, _pVideoCodecCtx->height, _pVideoCodecCtx->pix_fmt, _pVideoCodecCtx->width, _pVideoCodecCtx->height, AV_PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
        swsContext = img_convert_ctx;
        self.bShouldConvert = YES;
    }
    self.bCanPlay = YES;
    _pictureQueue = [HeYUV420PictureQueue pictureQueueWithStorageSize:CGSizeMake(pVideoCodecCtx->width, pVideoCodecCtx->height)];
}

- (void)clearAudioBuffer
{
    [_audioBufferQueue clear];
}
                   
- (void)clearPictureBuffer
{
    [_pictureQueue clear];
}

- (void)analyseVideoAndAudio
{
    while (1)
    {
        if(self.seekTime > 0)
        {
            self.audioClearFlag = YES;
            self.pictureClearFlag = YES;
            [self seekToTime:self.seekTime dir:(self.seekTime > self->frame_timer/1000)];
            self.seekTime = 0;
        }
        else
        {
            AVPacket packet;
            int ret = av_read_frame(_formatContext, &packet);
            if(0 == ret)
            {
                if(packet.stream_index == _videoStream)
                {
                    [self handVideoPacket:&packet];
                }
                else if(packet.stream_index == _audioStream)
                {
                    [self handAudioPacket:&packet];
                }
                av_packet_unref(&packet);
            }
            else
            {
                av_packet_unref(&packet);
                break ;
            }
        }
    }
}

- (void)handVideoPacket:(AVPacket*)packet
{
    int ret = avcodec_send_packet(_pVideoCodecCtx, packet);
    if(ret != 0)
        return ;
    ret = avcodec_receive_frame(_pVideoCodecCtx, _pFrame);
    if(ret != 0)
        return ;
    if(self.bShouldConvert)
    {
        sws_scale(swsContext, (const unsigned char* const*)_pFrame->data, _pFrame->linesize, 0, _pVideoCodecCtx->height,
                  _yuvFrame->data, _yuvFrame->linesize);
        [_pictureQueue addPictureWithFrame:_yuvFrame];
    }
    else
    {
        [_pictureQueue addPictureWithFrame:_pFrame];
    }
    av_frame_unref(_pFrame);
}

- (void)handAudioPacket:(AVPacket*)packet
{
    int nRet = avcodec_send_packet(_pAudioCodecCtx, packet);
    if(nRet < 0)
        return ;
    while(avcodec_receive_frame(_pAudioCodecCtx, _audioFrame) == 0)
    {
        int out_nb_samples = _pAudioCodecCtx->frame_size;//nb_samples: AAC-1024 MP3-1152
        const uint8_t **inBuffer = (const uint8_t **)_audioFrame->data;
        int out_count = out_nb_samples;
        int len2;
        
        audio_buffer* audioBuf = [_audioBufferQueue idleAudioBuffer];
        audioBuf->pts = _audioFrame->pts;
        len2 = swr_convert(swrContext, &audioBuf->buffer, out_count, inBuffer, _audioFrame->nb_samples);
        if (len2 < 0) {
            return ;
        }
        
        [_audioBufferQueue putBuffer:audioBuf];
        if (len2 == out_count) {
            if (swr_init(swrContext) < 0)
            {
                swr_free(&swrContext);
                NSLog(@"init swrContext failed");
                [self setupSwrContext];
            }
        }
        av_frame_unref(_audioFrame);
    }
}

- (void)startAnalyse
{
    if(!self.bCanPlay)
    {
        NSLog(@"can't play");
        return ;
    }
    self.bPause = NO;
    
    if(!self.bIsAnalysing)
    {
        __weak typeof(self) ws = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [ws analyseVideoAndAudio];
        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self showVideoFrame];
        });
        
        void *p = (__bridge void *) self;
        for(int i = 0 ; i < BUFFER_COUNT ; i ++){
            HandleOutputBufferCallBack(p, self->queueRef, self->buffers[i]);
        }
        
        self.bIsAnalysing = YES;
    }
    AudioQueueStart(queueRef, NULL);
}

- (double)get_audio_clock
{
    return self.audio_clock;
}

- (void)showVideoFrame
{
    if(self.pictureClearFlag)
    {
        [self clearPictureBuffer];
        self.pictureClearFlag = NO;
    }
    
    if(!self.bPause)
    {
        yuv420_picture* pic = [_pictureQueue getPicture];
        //计算帧率，平均每帧间隔时间
        double frameRate = av_q2d(_formatContext->streams[_videoStream]->avg_frame_rate);
        double step = 0.20;
        if(frameRate != 0)
        {
            step = 1/frameRate;
        }
        if(self->frame_last_pts != 0)
        {
            step = pic->pts - self->frame_last_pts;
            self->frame_timer += step;
            double diff = self->frame_timer - self->_audio_clock;
            if(diff < -20)
            {
                step = step - 40;
            }
            else if(diff > 20)
            {
                step = step + 40;
            }
            
            //        NSLog(@"frametime: %f, audioclock: %f", self->frame_timer, self->_audio_clock);
            
        }
        self->frame_last_pts = pic->pts;
        [self.delegate mediaAnalyser:self decodeVideo:pic frameSize:CGSizeMake(_pVideoCodecCtx->width, _pVideoCodecCtx->height)];
        
        step = step/1000;
        if(step > 1/frameRate + 0.05 || step < 1/frameRate - 0.05)
        {
            step = 1/frameRate;
        }
        NSLog(@"step: %f", step);
        //    NSLog(@"frametime: %f", self->frame_timer);
        static NSTimer* refreshTimer = nil;
        if (!refreshTimer) {
            refreshTimer = [NSTimer timerWithTimeInterval:step target:self selector:@selector(showVideoFrame) userInfo:nil repeats:YES];
            NSRunLoop* threadRunloop = [NSRunLoop currentRunLoop];
            [threadRunloop addTimer:refreshTimer forMode:NSRunLoopCommonModes];
            [threadRunloop run];
        }
        else
        {
            refreshTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:step];
        }
        
        [_pictureQueue freePicture:pic];
    }
    else
    {
        while (self.bPause) {
            
        }
        [self showVideoFrame];
    }
}

- (void)pause
{
    self.bPause = YES;
    AudioQueuePause(queueRef);
}

- (void)clear
{
//    if(_yuvFrame)
//    {
//        av_frame_free(&_yuvFrame);
//    }
//    av_frame_free(&_pFrame);
//    avcodec_close(_pVideoCodecCtx);
//    avformat_close_input(&_formatContext);
}

- (void)pickAudioPacketWithBuffer:(AudioQueueBufferRef)bufferRef
{
    if(self.audioClearFlag)
    {
        [self clearAudioBuffer];
        self.audioClearFlag = NO;
    }
    if(!self.bPause)
    {
        audio_buffer* audioBuffer = [_audioBufferQueue getBuffer];
        
        memcpy(bufferRef->mAudioData, audioBuffer->buffer, audioBuffer->size);
        bufferRef->mAudioDataByteSize = (UInt32)audioBuffer->size;
        AudioQueueEnqueueBuffer(queueRef, bufferRef, 0, nil);
        self.audio_clock = audioBuffer->pts;
        [_audioBufferQueue freeBuffer:audioBuffer];
    }
    else
    {
        while (self.bPause) {
            
        }
        [self pickAudioPacketWithBuffer:bufferRef];
    }
}

- (void)seekForward
{
    self.seekTime = self->frame_timer/1000+SEEK_STEP;
}

- (void)seekBackward
{
    self.seekTime = self->frame_timer/1000-SEEK_STEP;
}

- (void)setTimeStamp:(double)timestamp
{
    self.seekTime = timestamp;
}

- (void)seekToTime:(double)timestamp dir:(BOOL)forward
{
    double totalTime = _formatContext->duration/1000000;
    
    if(timestamp < 0)
    {
        timestamp = 0;
    }
    else if(timestamp > totalTime)
    {
        timestamp = totalTime;
    }
    
    AVRational timeBase = _formatContext->streams[_videoStream]->time_base;
    int64_t targetFrame = (int64_t)((double)timeBase.den / timeBase.num * timestamp);
    if(forward)
    {
        av_seek_frame(_formatContext, _videoStream, targetFrame, AVSEEK_FLAG_FRAME);
    }
    else
    {
        av_seek_frame(_formatContext, _videoStream, targetFrame, AVSEEK_FLAG_BACKWARD);
    }
    
    double targetTime = timestamp * 1000;
    self->frame_timer = targetTime;
    self->frame_last_pts = targetTime;
    self->_audio_clock = targetTime;
    
    avcodec_flush_buffers(_pAudioCodecCtx);
    avcodec_flush_buffers(_pVideoCodecCtx);
}

@end

void HandleOutputBufferCallBack (void *aqData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    HeMediaAnalyser* analyser = (__bridge HeMediaAnalyser*)aqData;
    if(!analyser)
        return ;
    [analyser pickAudioPacketWithBuffer:inBuffer];
}

