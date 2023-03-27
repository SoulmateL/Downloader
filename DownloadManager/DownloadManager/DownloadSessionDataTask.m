//
//  DownloadSessionDataTask.m
//  DownloadManager
//
//  Created by Apple on 2023/3/9.
//

#import "DownloadSessionDataTask.h"

@interface DownloadSessionDataTask ()
@property (nonatomic, strong) DownloadModel *downloadItem;
@end

@implementation DownloadSessionDataTask

- (instancetype)initWithDownloadItem:(DownloadModel *)item {
    if (self = [super init]) {
        self.downloadItem = item;
    }
    return self;
}

#pragma mark getter && setter

- (NSString *)taskId {
    return self.downloadItem.taskId;
}

- (NSOutputStream *)stream {
    if (!_stream) {
        _stream = [[NSOutputStream alloc] initToFileAtPath:self.downloadItem.savePath append:YES];
    }
    return _stream;
}

@end
