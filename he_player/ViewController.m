//
//  ViewController.m
//  CommonComponent_heqz
//
//  Created by work_lenovo on 2017/9/11.
//  Copyright © 2017年 work_lenovo. All rights reserved.
//

#import "ViewController.h"

#define CELL_HEIGHT 100

@interface DemoModel : NSObject

@property(nonatomic, strong)NSString* strDemoName;
@property(nonatomic, strong)NSString* strDemoClass;

+ (instancetype)modelWithDemoName:(NSString*)demoName demoClass:(NSString*)demoClass;

@end

@implementation DemoModel

+ (instancetype)modelWithDemoName:(NSString *)demoName demoClass:(NSString *)demoClass
{
    return [[self alloc] initWithDemoName:demoName demoClass:demoClass];
}

- (instancetype)initWithDemoName:(NSString *)demoName demoClass:(NSString *)demoClass
{
    if(self = [super init])
    {
        _strDemoName = demoName;
        _strDemoClass = demoClass;
    }
    
    return self;
}

@end

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong)NSArray* demoList;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self buildInterface];
}

- (NSArray *)demoList
{
    if(!_demoList)
    {
        NSMutableArray* array = [NSMutableArray array];
        
        DemoModel* ffmpegModel = [DemoModel modelWithDemoName:@"ffmpeg 播放器" demoClass:@"FFmpegViewController"];
        [array addObject:ffmpegModel];
        
        DemoModel* avPalyerModel = [DemoModel modelWithDemoName:@"AVPlayer 播放器" demoClass:@"AVPlayerViewController"];
        [array addObject:avPalyerModel];

        _demoList = array;
    }
    
    return _demoList;
}

- (void)buildInterface
{
    self.title = @"player列表";
    
    UITableView* tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:tableView];
    
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.demoList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* strCell = @"cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:strCell];
    if(!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strCell];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    for(UIView* subView in cell.contentView.subviews)
    {
        [subView removeFromSuperview];
    }
    
    UILabel* labelName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, CELL_HEIGHT)];
    [cell.contentView addSubview:labelName];
    
    DemoModel* model = [self.demoList objectAtIndex:indexPath.row];
    labelName.text = model.strDemoName;
    labelName.font = [UIFont systemFontOfSize:15];
    labelName.textColor = [UIColor blackColor];
    labelName.textAlignment = NSTextAlignmentCenter;
    
    CGFloat fFac = 1/[UIScreen mainScreen].scale;
    UIView* lineView = [[UIView alloc] initWithFrame:CGRectMake(10, CELL_HEIGHT - fFac, self.view.bounds.size.width - 20, fFac)];
    lineView.backgroundColor = [UIColor grayColor];
    [cell.contentView addSubview:lineView];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DemoModel* model = [self.demoList objectAtIndex:indexPath.row];
    Class class = NSClassFromString(model.strDemoClass);
    if(![class isSubclassOfClass:[UIViewController class]])
    {
        return ;
    }
    
    UIViewController* vc = [[class alloc] init];
    vc.title = model.strDemoName;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
