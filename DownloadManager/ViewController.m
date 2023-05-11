//
//  ViewController.m
//  DownloadManager
//
//  Created by Apple on 2023/3/1.
//

#import "ViewController.h"
#import "DownloadManager.h"
#import "DownloadTableViewCell.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    
    DownloadModel *model1 = [[DownloadModel alloc] init];
//    model1.fileURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4";

    model1.fileURL = @"https://media.w3.org/2010/05/sintel/trailer.mp4";
//    model1.fileURL = @"https://speed.hetzner.de/100MB.bin";

    DownloadModel *model2 = [[DownloadModel alloc] init];
    model2.queuePriority = NSOperationQueuePriorityLow;
    model2.fileURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_5mb.mp4";

    DownloadModel *model3 = [[DownloadModel alloc] init];
    model3.queuePriority = NSOperationQueuePriorityHigh;
    model3.fileURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_2mb.mp4";
    [DownloadManager shareManager].maxConcurrentDownloads = 1;
    [DownloadManager shareManager].allowsCellularAccess = NO;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![DownloadManager shareManager].taskList.count) {
            [[DownloadManager shareManager] startWithDownloadItem:model1];
            [[DownloadManager shareManager] startWithDownloadItem:model2];
            [[DownloadManager shareManager] startWithDownloadItem:model3];
        }
        
        else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[DownloadManager shareManager] resumeAllDownloadTask];
            });
        }
    });
    
    
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
    [[DownloadManager shareManager] pauseAllDownloadTask];
    [self.tableView reloadData];
}

- (void)resume:(UIButton *)sender {
    if (![DownloadManager shareManager].taskList.count) {
        DownloadModel *model1 = [[DownloadModel alloc] init];
//        model1.fileURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4";
        model1.fileURL = @"https://media.w3.org/2010/05/sintel/trailer.mp4";
//        model1.fileURL = @"https://speed.hetzner.de/100MB.bin";
    
        DownloadModel *model2 = [[DownloadModel alloc] init];
        model2.queuePriority = NSOperationQueuePriorityLow;
        model2.fileURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_5mb.mp4";

        DownloadModel *model3 = [[DownloadModel alloc] init];
        model3.queuePriority = NSOperationQueuePriorityHigh;
        model3.fileURL = @"https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_2mb.mp4";
        [[DownloadManager shareManager] startWithDownloadItem:model1];
        [[DownloadManager shareManager] startWithDownloadItem:model2];
        [[DownloadManager shareManager] startWithDownloadItem:model3];
    }
    else {
        [[DownloadManager shareManager] resumeAllDownloadTask];
    }
    [self.tableView reloadData];
}

- (void)delete:(UIButton *)sender {
    [[DownloadManager shareManager] removeAllDownloadTask];
    [self.tableView reloadData];
}

- (void)status:(NSNotification *)notification {
    DownloadModel *model = notification.object;
    if (model.downloadStatus == DownloadStateFinished) {
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
        return [DownloadManager shareManager].downloadingList.count;
    }
    return [DownloadManager shareManager].finishedList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        DownloadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([DownloadTableViewCell class])];
        cell.dataModel = [DownloadManager shareManager].downloadingList[indexPath.row];
        return cell;
    }
    DownloadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([DownloadTableViewCell class])];
    cell.dataModel = [DownloadManager shareManager].finishedList[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) return;
    DownloadModel *model = [DownloadManager shareManager].downloadingList[indexPath.row];
    [[DownloadManager shareManager] resumeOrPauseWithTaskId:model.taskId];
}


@end
