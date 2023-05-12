//
//  DownloadTableViewCell.m
//  YYDownloadManager
//
//  Created by Jonathan on 2023/5/9.
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

- (void)updateWithStatus:(YYDownloadStatus)status {
    switch (status) {
        case YYDownloadStatusUnknow:
            self.status.text = @"未开始";
            break;
        case YYDownloadStatusWaiting:
            self.status.text = @"等待下载";
            break;
        case YYDownloadStatusDownloading:
            self.status.text = @"正在下载";
            break;
        case YYDownloadStatusPaused:
            self.status.text = @"暂停下载";
            break;
        case YYDownloadStatusFailed:
            self.status.text = @"下载失败";
            break;
        case YYDownloadStatusFinished:
            self.status.text = @"下载完成";
            break;
            
        default:
            break;
    }
}

- (void)setDataModel:(NSObject<YYDownloadTaskDelegate> *)dataModel {
    _dataModel = dataModel;
    self.title.text = dataModel.fileName;
    [self updateWithStatus:dataModel.downloadStatus];
    self.progress.text = [NSString stringWithFormat:@"%lld/%lld",dataModel.downloadedSize,dataModel.totalSize];
}

- (void)progress:(NSNotification *)notification {
    NSObject<YYDownloadTaskDelegate> *model = notification.object;
    if (![model.downloadURL isEqualToString:self.dataModel.downloadURL]) return;
    self.progress.text = [NSString stringWithFormat:@"%lld/%lld",model.downloadedSize,model.totalSize];

}

- (void)status:(NSNotification *)notification {
    NSObject<YYDownloadTaskDelegate> *model = notification.object;
    if (![model.downloadURL isEqualToString:self.dataModel.downloadURL]) return;
    [self updateWithStatus:model.downloadStatus];
}

@end
