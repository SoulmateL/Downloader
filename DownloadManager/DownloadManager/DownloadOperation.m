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
@property (nonatomic, assign, getter = isExecuting) BOOL executing;
@property (nonatomic, assign, getter = isFinished) BOOL finished;
@property (nonatomic, strong) DownloadSessionDataTask *task;
@end

@implementation DownloadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithDownloadItem:(DownloadModel *)item {
    if (self = [super init]) {
        self.queuePriority = item.queuePriority;
        _downloadItem = item;
        _executing = NO;
        _finished = NO;
    }
    return self;
}

- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            [self completeOperation];
            return;
        }
        self.executing = YES;
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
        if (self.isCancelled) return;
        if (self.isFinished) return;
        [super cancel];
   
        if (self.isExecuting || self.isFinished) {
            if (self.isExecuting) self.executing = NO;
            if (!self.isFinished) self.finished = YES;
        }
        [self reset];
    }
}

- (void)done {
    [self completeOperation];
    if (self.doneBlock) {
        self.doneBlock();
    }
}

- (void)completeOperation {
    self.executing = NO;
    self.finished = YES;
    [self reset];
}

- (void)reset {
    if (self.task) {
        [[DownloadSessionManager sharedManager] cancelTask:self.task];
    }
    self.task = nil;
}

#pragma mark getter && setter

- (BOOL)isAsynchronous {
    return YES;
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}
@end
