//
//  HePlayer.m
//  he_player
//
//  Created by qingzhao on 2018/7/12.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import "HePlayer.h"
#import "EGL_Program.h"
#import "HeMediaAnalyser.h"
#import "HePlayerProgressView.h"

#import <OpenGLES/ES3/gl.h>

@interface HePlayer()<HeMediaAnalyserDelegate, HePlayerProgressViewDelegate, UIGestureRecognizerDelegate>

@property(nonatomic, weak)UIView* renderView;
@property(nonatomic, strong)EAGLContext* glContext;
@property(nonatomic, strong)HeMediaAnalyser* mediaAnalyser;
@property(nonatomic, strong)NSTimer* timer;
@property(nonatomic, strong)UIImageView* playImage;
@property(nonatomic, assign)BOOL isPlaying;
@property(nonatomic, assign)BOOL canPlay;
@property(nonatomic, strong)HePlayerProgressView* progressView;

@end

@implementation HePlayer
{
    GLuint frameBuffer;
    GLuint renderBuffer;
    GLuint texture_y;
    GLuint texture_u;
    GLuint texture_v;
}

- (void)dealloc
{
    self.mediaAnalyser.delegate = nil;
    self.mediaAnalyser.bCanPlay = NO;
}

- (instancetype)initWithMediaPath:(NSString *)path renderView:(UIView*)view
{
    if(self = [super init])
    {
        self.renderView = view;
        [self buildInterface];
        [self setGLContext];
        [self setupAudioSession];
        [self setupMediaAnalyserWithPath:path];
    }
    return self;
}

- (void)buildInterface
{
    const CGFloat fW = 50;
    UIImageView* playImage = [[UIImageView alloc] initWithFrame:CGRectMake(self.renderView.bounds.size.width/2 - fW/2, self.renderView.bounds.size.height/2 - fW/2, fW, fW)];
    playImage.image = [UIImage imageNamed:@"play_button"];
    [self.renderView addSubview:playImage];
    self.playImage = playImage;
    
    UITapGestureRecognizer* tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRenderView)];
    tapGes.delegate = self;
    [self.renderView addGestureRecognizer:tapGes];
    
    UISwipeGestureRecognizer* swipGes = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(seekGesture:)];
    swipGes.direction = UISwipeGestureRecognizerDirectionLeft;
    swipGes.delegate = self;
    [self.renderView addGestureRecognizer:swipGes];
    
    UISwipeGestureRecognizer* swipGesRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(seekGesture:)];
    swipGesRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipGesRight.delegate = self;
    [self.renderView addGestureRecognizer:swipGesRight];
    
    [self.renderView addSubview:self.progressView];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint pt = [gestureRecognizer locationInView:self.renderView];
    if(pt.y > self.progressView.frame.origin.y)
        return NO;
    return YES;
}

- (void)seekGesture:(UISwipeGestureRecognizer*)swipGes
{
    UISwipeGestureRecognizerDirection dir = swipGes.direction;
    if(UISwipeGestureRecognizerDirectionLeft == dir)
    {
        [self.mediaAnalyser seekBackward];
    }
    else if(UISwipeGestureRecognizerDirectionRight == dir)
    {
        [self.mediaAnalyser seekForward];
    }
}

- (void)tapRenderView
{
    if(!self.canPlay)
        return ;
    
    self.playing = !self.playing;
}

- (void)setupMediaAnalyserWithPath:(NSString*)path
{
    self.mediaAnalyser = [[HeMediaAnalyser alloc] initWithMediaPath:path delegate:self];
    self.canPlay = [self.mediaAnalyser bCanPlay];
}

- (void)setCanPlay:(BOOL)canPlay
{
    _canPlay = canPlay;
    self.playImage.hidden = !canPlay;
}

- (void)setPlaying:(BOOL)playing
{
    _playing = playing;
    self.playImage.hidden = playing;
    if(playing)
    {
        [self.mediaAnalyser startAnalyse];
    }
    else
    {
        [self.mediaAnalyser pause];
    }
}

- (void)setupAudioSession
{
    
}

- (void)useContext
{
    if([EAGLContext currentContext] != self.glContext)
    {
        [EAGLContext setCurrentContext:self.glContext];
    }
}

- (void)setupStorage
{
    CAEAGLLayer* renderLayer = (CAEAGLLayer*)[self.renderView layer];
    [self.glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:renderLayer];
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"创建缓冲区错误 0x%x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return ;
    }
    
    //    glViewport(0,0, self.bounds.size.width, self.bounds.size.height);
    GLint backingWidth, backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    glViewport(0, 0, backingWidth, backingHeight);
}

- (void)setGLContext
{
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    self.glContext = context;
    [self useContext];
    
    CAEAGLLayer* renderLayer = (CAEAGLLayer*)[self.renderView layer];
    renderLayer.contentsScale = [[UIScreen mainScreen] scale];
    renderLayer.opaque = YES;
    renderLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    glDisable(GL_DEPTH_TEST);
    
    GLuint fb;
    glGenFramebuffers(1, &fb);
    glBindFramebuffer(GL_FRAMEBUFFER, fb);
    frameBuffer = fb;
    
    GLuint rb;
    glGenRenderbuffers(1, &rb);
    glBindRenderbuffer(GL_RENDERBUFFER, rb);
    renderBuffer = rb;
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, rb);
    [self setupStorage];
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    EGL_Program* program = [EGL_Program sharedProgram];
    NSString* vertextShader = [[NSBundle mainBundle] pathForResource:@"displayVertexShader.vs" ofType:nil];
    [program loadShader:GL_VERTEX_SHADER shaderPath:vertextShader];
    NSString* fragmentShader = [[NSBundle mainBundle] pathForResource:@"displayFragmentShader.fs" ofType:nil];
    [program loadShader:GL_FRAGMENT_SHADER shaderPath:fragmentShader];
    
    [program linkProgram];
    [[EGL_Program sharedProgram] useProgram];
    
    GLuint texy;
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &texy);
    glBindTexture(GL_TEXTURE_2D, texy);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    texture_y = texy;
    
    GLuint texu;
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &texu);
    glBindTexture(GL_TEXTURE_2D, texu);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    texture_u = texu;
    
    GLuint texv;
    glActiveTexture(GL_TEXTURE2);
    glGenTextures(1, &texv);
    glBindTexture(GL_TEXTURE_2D, texv);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    texture_v = texv;
}

- (void)play
{
    
}
- (void)pause
{
    
}

- (void)goFowartWithTimeInterval:(NSTimeInterval)nVal
{
    
}

- (void)goBackWithTimeInterval:(NSTimeInterval)nVal
{
    
}

- (void)destroy
{
    [self.timer invalidate];
    [self.mediaAnalyser clear];
}

- (void)mediaAnalyser:(HeMediaAnalyser *)analyser decodeVideo:(yuv420_picture *)picture frameSize:(CGSize)size
{
    if(self.renderStorageChanged)
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.renderStorageChanged = NO;
            [self setupStorage];
            self.playImage.center = CGPointMake(self.renderView.bounds.size.width/2, self.renderView.bounds.size.height/2);
            [self.progressView  adjustFrame];
        });
    }
    
    double pts = picture->pts;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView changeTimePositionWithTime:pts];
    });
    
    [self useContext];
    
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    
    int width = size.width;
    int height = size.height;
    
    unsigned char* ybits = picture->y;
    unsigned char* ubits = picture->u;
    unsigned char* vbits = picture->v;
    
    GLint yIndex = [[EGL_Program sharedProgram] uniformLocationOfName:@"tex_y"];
    GLint uIndex = [[EGL_Program sharedProgram] uniformLocationOfName:@"tex_u"];
    GLint vIndex = [[EGL_Program sharedProgram] uniformLocationOfName:@"tex_v"];
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture_y);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, ybits);
    
    glUniform1i(yIndex, 0);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, texture_u);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, ubits);
    
    glUniform1i(uIndex, 1);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, texture_v);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, vbits);
    
    glUniform1i(vIndex, 2);
    
    GLint backingWidth, backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    CGFloat fWScale = width/(CGFloat)backingWidth;
    CGFloat fHScale = height/(CGFloat)backingHeight;
    CGFloat fScale = 0;
    if(fWScale > fHScale)
    {
        fScale = fWScale;
    }
    else
    {
        fScale = fHScale;
    }
    
    GLfloat fCoorW = fWScale/fScale;
    GLfloat fCoorH = fHScale/fScale;
    const GLfloat vertexVertices[] = {
        -fCoorW, -fCoorH,
        fCoorW, -fCoorH,
        -fCoorW,  fCoorH,
        fCoorW, fCoorH
    };
    
    static const GLfloat textureVertices[] = {
        0.0f,  1.0f,
        1.0f,  1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f
    };
    
    GLint vertexIndex = [[EGL_Program sharedProgram] attribLocationOfName:@"a_postion"];
    glVertexAttribPointer(vertexIndex, 2, GL_FLOAT, GL_FALSE, 0, vertexVertices);
    glEnableVertexAttribArray(vertexIndex);
    GLint textureIndex = [[EGL_Program sharedProgram] attribLocationOfName:@"textureIn"];
    glEnableVertexAttribArray(textureIndex);
    glVertexAttribPointer(textureIndex, 2, GL_FLOAT, GL_FALSE, 0, textureVertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
}

- (void)mediaAnalyser:(HeMediaAnalyser *)analyser didFinished:(BOOL)finished error:(NSError *)error
{
    if(error)
    {
        NSLog(@"error: %@", error);
    }
    [self setPlaying:NO];
    [self.progressView changeTimePositionWithTime:0];
}

- (void)mediaAnalyser:(HeMediaAnalyser *)analyser getVideoDuration:(CGFloat)duration
{
    self.progressView.nDuration = duration;
}

- (HePlayerProgressView *)progressView
{
    if(!_progressView)
    {
        _progressView = [[HePlayerProgressView alloc] initWithFrame:CGRectMake(0, self.renderView.bounds.size.height - 50, self.renderView.bounds.size.width, 20) delegate:self];
    }
    return _progressView;
}

- (void)changeToTime:(CGFloat)timestamp
{
    [self.mediaAnalyser setTimeStamp:timestamp];
}

@end
