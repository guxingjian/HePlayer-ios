//
//  FFmpegViewController.m
//  he_player
//
//  Created by qingzhao on 2018/7/31.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import "FFmpegViewController.h"

#import "HePlayerView.h"

#define SCREEN_HEIGHT CGRectGetHeight([[UIScreen mainScreen] bounds])
#define SCREEN_WIDTH  CGRectGetWidth([[UIScreen mainScreen] bounds])

#define SCREEN_MIN MIN(SCREEN_HEIGHT,SCREEN_WIDTH)
#define SCREEN_MAX MAX(SCREEN_HEIGHT,SCREEN_WIDTH)

@interface FFmpegViewController ()

@property(nonatomic, strong)HePlayerView* playView;

@end

@implementation FFmpegViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
//        NSString* strVideoPath = [[NSBundle mainBundle] pathForResource:@"movie.mkv" ofType:nil];
    //    NSString* strVideoPath = @"rtmp://47.93.220.12:1935/live/heqz";
    NSString* strVideoPath = @"http://47.93.220.12/video/movie.mkv";
//        NSString* strVideoPath = @"http://localhost:8088/video/movie.mkv";
    HePlayerView* playerView = [[HePlayerView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) mediaPath:strVideoPath];
    [self.view addSubview:playerView];
    self.playView = playerView;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    if(CGSizeEqualToSize(size, CGSizeMake(SCREEN_MIN, SCREEN_MAX)))
    {
        self.playView.frame = CGRectMake(0, 100, SCREEN_MIN, 300);
    }
    else if(CGSizeEqualToSize(size, CGSizeMake(SCREEN_MAX, SCREEN_MIN)))
    {
        self.playView.frame = CGRectMake(0, 0, SCREEN_MAX, SCREEN_MIN);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
