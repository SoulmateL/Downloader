//
//  DownloadTableViewCell.m
//  DownloadManager
//
//  Created by Apple on 2023/5/9.
//

#import "DownloadTableViewCell.h"

@interface DownloadTableViewCell ()
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UILabel *status;
@property (nonatomic, strong) UILabel *progress;
@end

@implementation DownloadTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setUI];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progress:) name:kDownloadProgressUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(status:) name:kDownloadStatusChangedNotification object:nil];

    }
    return self;
}

- (void)setUI {
    self.title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 22)];
    
    self.status = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, 100, 22)];
    
    self.progress = [[UILabel alloc] initWithFrame:CGRectMake(100, 22, [UIScreen mainScreen].bounds.size.width-100, 22)];


    [self.contentView addSubview:self.title];
    [self.contentView addSubview:self.status];
    [self.contentView addSubview:self.progress];
    
}

- (void)updateWithStatus:(DownloadState)status {
    switch (status) {
        case DownloadStateNotStarted:
            self.status.text = @"未开始";
            break;
        case DownloadStateWaiting:
            self.status.text = @"等待下载";
            break;
        case DownloadStateDownloading:
            self.status.text = @"正在下载";
            break;
        case DownloadStatePaused:
            self.status.text = @"暂停下载";
            break;
        case DownloadStateFailed:
            self.status.text = @"下载失败";
            break;
        case DownloadStateFinished:
            self.status.text = @"下载完成";
            break;
            
        default:
            break;
    }
}

- (void)setDataModel:(DownloadModel *)dataModel {
    _dataModel = dataModel;
    self.title.text = dataModel.fileName;
    [self updateWithStatus:dataModel.downloadStatus];
    self.progress.text = [NSString stringWithFormat:@"%lld/%lld",dataModel.downloadedSize,dataModel.totalSize];
}

- (void)progress:(NSNotification *)notification {
    DownloadModel *model = notification.object;
    if (![model.taskId isEqualToString:self.dataModel.taskId]) return;
    self.progress.text = [NSString stringWithFormat:@"%lld/%lld",model.downloadedSize,model.totalSize];

}

- (void)status:(NSNotification *)notification {
    DownloadModel *model = notification.object;
    if (![model.taskId isEqualToString:self.dataModel.taskId]) return;
    [self updateWithStatus:model.downloadStatus];
}

@end
