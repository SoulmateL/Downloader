//
//  ViewController.m
//  DownloadManager
//
//  Created by Apple on 2023/3/1.
//

#import "ViewController.h"
#import "DownloadManager.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (nonatomic, strong) DownloadModel *model;

@property (nonatomic, strong) DownloadModel *model1;

@property (nonatomic, strong) DownloadModel *model2;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[DownloadManager shareManager] removeAllDownloadTask];
//    [DownloadManager shareManager].maxConcurrentDownloads = 2;
//    [DownloadManager shareManager].allowsCellularAccess = YES;
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progress:) name:kDownloadProgressUpdateNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(status:) name:kDownloadStatusChangedNotification object:nil];
//
//    self.model = [[DownloadModel alloc] init];
//    self.model.fileURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4";
//    [[DownloadManager shareManager] startWithDownloadItem:self.model];
//
//    self.model2 = [[DownloadModel alloc] init];
//    self.model2.queuePriority = NSOperationQueuePriorityVeryLow;
//    self.model2.fileURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_5mb.mp4";
//    [[DownloadManager shareManager] startWithDownloadItem:self.model2];
//
//    self.model1 = [[DownloadModel alloc] init];
//    self.model1.fileURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_2mb.mp4";
//    self.model1.queuePriority = NSOperationQueuePriorityHigh;
//    [[DownloadManager shareManager] startWithDownloadItem:self.model1];
    
    for (UIView *subview in self.view.subviews) {
        subview.hidden = YES;
    }
    

    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 100, 200, 50)];
        label.text = @"Hello, World!";
        label.textColor = [UIColor redColor];
        label.font = [UIFont systemFontOfSize:30];
        [self.view addSubview:label];

        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = label.bounds;
        gradientLayer.colors = @[(__bridge id)[UIColor orangeColor].CGColor, (__bridge id)[UIColor cyanColor].CGColor];
        gradientLayer.startPoint = CGPointMake(0, 0.5);
        gradientLayer.endPoint = CGPointMake(1, 0.5);
        label.layer.mask = gradientLayer;


        
//        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(50, 100, 200, 200)];
//        containerView.backgroundColor = [UIColor whiteColor];
//        [self.view addSubview:containerView];
//
//        // 创建图层
//        CALayer *layer = [[CALayer alloc] init];
//        layer.frame = CGRectMake(50, 50, 100, 100);
//        layer.backgroundColor = [UIColor redColor].CGColor;
//        [containerView.layer addSublayer:layer];
//
//        // 创建遮罩层
//        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
//        maskLayer.frame = CGRectMake(0, 0, 200, 200); // 大于图层大小
//        maskLayer.backgroundColor = [UIColor blackColor].CGColor;
//        maskLayer.path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 100, 100)].CGPath;
//        layer.mask = maskLayer;
//
//        // 添加动画
//        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
//        animation.duration = 2.0;
//        animation.toValue = @(200); // 修改遮

    });

    
    // 将要显示的图层添加到父图层中



}

- (IBAction)test:(UIButton *)sender {
    [[DownloadManager shareManager] resumeOrPauseWithTaskId:self.model.taskId];
    
}

- (void)progress:(NSNotification *)noti {
    DownloadModel *model = noti.object;
    NSLog(@"~~~~~~~~~~~~%lld",model.downloadedSize);
    NSLog(@"~~~~~~~~~~~~%lld",model.totalSize);
    self.label1.text = [NSString stringWithFormat:@"%.2f",model.downloadProgress];
//    self.label2.text = [NSString stringWithFormat:@"%fM/s",model.downloadSpeed];
}

- (void)status:(NSNotification *)noti {
    DownloadModel *model = noti.object;
    NSLog(@"~~~~~~~~~~~~%zd",model.downloadStatus);
}

@end
