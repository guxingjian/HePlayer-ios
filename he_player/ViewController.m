//
//  ViewController.m
//  he_player
//
//  Created by qingzhao on 2018/7/12.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import "ViewController.h"
#import "HePlayerView.h"

#define SCREEN_HEIGHT CGRectGetHeight([[UIScreen mainScreen] bounds])
#define SCREEN_WIDTH  CGRectGetWidth([[UIScreen mainScreen] bounds])

#define SCREEN_MIN MIN(SCREEN_HEIGHT,SCREEN_WIDTH)
#define SCREEN_MAX MAX(SCREEN_HEIGHT,SCREEN_WIDTH)

@interface ViewController ()

@property(nonatomic, strong)HePlayerView* playView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString* strVideoPath = [[NSBundle mainBundle] pathForResource:@"movie2.mkv" ofType:nil];
    HePlayerView* playerView = [[HePlayerView alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, 300) mediaPath:strVideoPath];
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


@end
