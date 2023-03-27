//
//  DownloadOperation.m
//  DownloadManager
//
//  Created by Apple on 2023/3/3.
//

#import "DownloadOperation.h"
#import "DownloadSessionManager.h"
#import "DownloadSessionDataTask.h"

@interface DownloadOperation ()
@property (nonatomic, strong) DownloadModel *downloadItem;
@property (nonatomic, assign) BOOL isExecuting;
@property (nonatomic, assign) BOOL isFinished;
@property (nonatomic, strong) DownloadSessionDataTask *task;
@end

@implementation DownloadOperation

@synthesize isExecuting = _isExecuting;
@synthesize isFinished = _isFinished;

- (instancetype)initWithDownloadItem:(DownloadModel *)item {
    if (self = [super init]) {
        self.queuePriority = item.queuePriority;
        self.downloadItem = item;
        self.isExecuting = NO;
        self.isFinished = NO;
    }
    return self;
}

- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            self.downloadItem.downloadStatus = DownloadStateWaiting;
            return;
        }
        self.isExecuting = YES;
        self.downloadItem.downloadStatus = DownloadStateDownloading;
        self.task = [[DownloadSessionManager sharedManager] downloadTaskWithDownloadItem:self.downloadItem];
        __weak __typeof(self) weakSelf = self;
        self.task.completionHander = ^(NSError * _Nonnull error) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (!error) {
                strongSelf.downloadItem.downloadStatus = DownloadStateFinished;
            }else if (error.code != -999){
                strongSelf.downloadItem.downloadStatus = DownloadStateFailed;
            }
            [strongSelf done];
        };
    }
}

- (void)cancel {
    @synchronized (self) {
        if (self.isFinished) return;
        [super cancel];
        [self done];
    }
}

- (void)done {
    if (self.task) {
        [[DownloadSessionManager sharedManager] cancelTask:self.task];
    }
    self.isFinished = YES;
    self.isExecuting = NO;
    self.task = nil;
    if (self.doneBlock) {
        self.doneBlock();
    }
}

#pragma mark getter && setter

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isExecuting {
    return _isExecuting;
}

- (BOOL)isFinished {
    return _isFinished;
}

- (void)setIsExecuting:(BOOL)isExecuting {
    if (_isExecuting != isExecuting) {
        [self willChangeValueForKey:@"isExecuting"];
        _isExecuting = isExecuting;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)setIsFinished:(BOOL)isFinished {
    if (_isFinished != isFinished) {
        [self willChangeValueForKey:@"isFinished"];
        _isFinished = isFinished;
        [self didChangeValueForKey:@"isFinished"];
    }
}

@end
