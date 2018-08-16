//
//  AVPlayerViewController.m
//  he_player
//
//  Created by qingzhao on 2018/7/31.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import "AVPlayerViewController.h"
#import "AVPlayerView.h"

@interface AVPlayerViewController ()

@end

@implementation AVPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
//    NSURL* strVideoPath = [[NSBundle mainBundle] URLForResource:@"test.mp4" withExtension:nil];
    NSString* strVideoPath = @"http://47.93.220.12/video/movie.mp4";
    
    AVPlayerView* playerView = [[AVPlayerView alloc] initWithFrame:CGRectMake(0, 80, self.view.bounds.size.width, 300) mediaPath:strVideoPath];
    [self.view addSubview:playerView];
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
