//
//  ViewController.m
//  YYDownloadManager
//
//  Created by Jonathan on 2023/3/1.
//

#import "ViewController.h"
#import "YYDownloadManager.h"
#import "DownloadTableViewCell.h"
#import "YYDownloadTask.h"
#import "YYDownloadSessionManager.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    
    YYDownloadTask *model1 = [[YYDownloadTask alloc] init];
    model1.downloadURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4";

//    model1.downloadURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4";
//    model1.fileURL = @"https://speed.hetzner.de/100MB.bin";

    YYDownloadTask *model2 = [[YYDownloadTask alloc] init];
    model2.queuePriority = NSOperationQueuePriorityLow;
    model2.downloadURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_5mb.mp4";

    YYDownloadTask *model3 = [[YYDownloadTask alloc] init];
    model3.queuePriority = NSOperationQueuePriorityHigh;
    model3.downloadURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_2mb.mp4";

    if (![YYDownloadManager shareManager].tasks.count) {
        [[YYDownloadManager shareManager] startWithTask:model1];
        [[YYDownloadManager shareManager] startWithTask:model2];
        [[YYDownloadManager shareManager] startWithTask:model3];
    }

    else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [[YYDownloadManager shareManager] resumeAllDownloadingTask];
        });
    }
    
    
    UIButton *resume = [UIButton buttonWithType:UIButtonTypeSystem];
    [resume setTitle:@"全部继续" forState:UIControlStateNormal];
    resume.frame = CGRectMake(20, 40, 100, 40);
    [resume addTarget:self action:@selector(resume:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *pause = [UIButton buttonWithType:UIButtonTypeSystem];
    [pause setTitle:@"全部暂停" forState:UIControlStateNormal];
    pause.frame = CGRectMake(150, 40, 100, 40);
    [pause addTarget:self action:@selector(pause:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *delete = [UIButton buttonWithType:UIButtonTypeSystem];
    [delete setTitle:@"全部删除" forState:UIControlStateNormal];
    delete.frame = CGRectMake(230, 40, 100, 40);
    [delete addTarget:self action:@selector(delete:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:resume];
    [self.view addSubview:pause];
    [self.view addSubview:delete];

    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 100) style:UITableViewStyleGrouped];
    self.tableView.rowHeight = 44;
    self.tableView.backgroundColor = [UIColor redColor];
    [self.tableView registerClass:[DownloadTableViewCell class] forCellReuseIdentifier:NSStringFromClass([DownloadTableViewCell class])];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.view addSubview:self.tableView];

    
    [self.tableView reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(status:) name:kDownloadStatusChangedNotification object:nil];
}

- (void)pause:(UIButton *)sender {
//    [YYDownloadManager shareManager].configuration.allowsCellularAccess = NO;
    [[YYDownloadManager shareManager] pauseAllDownloadingTask];
    [self.tableView reloadData];
}

- (void)resume:(UIButton *)sender {
//    [YYDownloadManager shareManager].configuration.allowsCellularAccess = NO;
    if (![YYDownloadManager shareManager].tasks.count) {
        YYDownloadTask *model1 = [[YYDownloadTask alloc] init];
        model1.downloadURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4";

//        model1.downloadURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4";
    //    model1.fileURL = @"https://speed.hetzner.de/100MB.bin";

        YYDownloadTask *model2 = [[YYDownloadTask alloc] init];
        model2.queuePriority = NSOperationQueuePriorityLow;
        model2.downloadURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_5mb.mp4";

        YYDownloadTask *model3 = [[YYDownloadTask alloc] init];
        model3.queuePriority = NSOperationQueuePriorityHigh;
        model3.downloadURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_2mb.mp4";
        [[YYDownloadManager shareManager] startWithTask:model1];
        [[YYDownloadManager shareManager] startWithTask:model2];
        [[YYDownloadManager shareManager] startWithTask:model3];
    }
    else {
        [[YYDownloadManager shareManager] resumeAllDownloadingTask];
    }
    [self.tableView reloadData];
}

- (void)delete:(UIButton *)sender {
    [[YYDownloadManager shareManager] removeAllDownloadTask];
    [self.tableView reloadData];
}

- (void)status:(NSNotification *)notification {
    NSObject<YYDownloadTaskDelegate> *model = notification.object;
    if (model.downloadStatus == YYDownloadStatusFinished) {
        [self.tableView reloadData];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"下载列表";
    }
    return @"完成列表";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [YYDownloadManager shareManager].downloadingTasks.count;
    }
    return [YYDownloadManager shareManager].downloadedTasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        DownloadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([DownloadTableViewCell class])];
        cell.dataModel = [YYDownloadManager shareManager].downloadingTasks[indexPath.row];
        return cell;
    }
    DownloadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([DownloadTableViewCell class])];
    cell.dataModel = [YYDownloadManager shareManager].downloadedTasks[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) return;
    [[YYDownloadManager shareManager] changeTaskStatusWhenUserTaped:[YYDownloadManager shareManager].downloadingTasks[indexPath.row]];
}


@end
