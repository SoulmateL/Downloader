//
//  DownloadManager.m
//  DownloadManager
//
//  Created by Apple on 2023/3/2.
//

#import "DownloadManager.h"
#import "DownloadOperation.h"
#import "DownloadHelper.h"
#import "DownloadItemManager.h"
#import "AFNetworking.h"
#include <signal.h>


static NSString *const kTaskQueueName = @"com.jonathan.download.queue";

@interface DownloadManager ()
/// 下载任务队列
@property (nonatomic, strong) NSOperationQueue *taskQueue;
/// 下载任务锁
@property (nonatomic, strong) NSLock *lock;
/// 任务map
@property (nonatomic, strong) NSMutableDictionary<NSString *,DownloadOperation *> *taskOperationMap;
/// 网络状态
@property (nonatomic, assign) AFNetworkReachabilityStatus reachabilityStatus;
/// 网络状态监听
@property (nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;

@end

@implementation DownloadManager


+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    static DownloadManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (void)dealloc {
    [self.taskQueue cancelAllOperations];
}

- (instancetype)init {
    if (self = [super init]) {
        _maxConcurrentDownloads = 1;
        _taskQueue = [[NSOperationQueue alloc] init];
        _taskQueue.name = kTaskQueueName;
        _taskQueue.maxConcurrentOperationCount = _maxConcurrentDownloads;
        _allowsCellularAccess = YES;
        _taskOperationMap = [NSMutableDictionary dictionary];
        self.lock = [[NSLock alloc] init];
        [self addReachabilityMonitor];
        [self addNotifications];
        
    }
    return self;
}

- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

- (void)addReachabilityMonitor {
    _reachabilityManager = [AFNetworkReachabilityManager manager];
    [_reachabilityManager startMonitoring];
    _reachabilityStatus = _reachabilityManager.networkReachabilityStatus;
    __weak typeof(self) weakSelf = self;
    [_reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.reachabilityStatus = status;
        /// WiFi
        if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
            [strongSelf resumeAllDownloadTask];
        }
        /// WWAN
        else if (status == AFNetworkReachabilityStatusReachableViaWWAN) {
            if (!strongSelf.allowsCellularAccess) {
                [strongSelf pauseAllDownloadTask];
            }
        }
        else {
            [strongSelf pauseAllDownloadTask];
            NSLog(@"无网络连接");
        }
    }];
}

#pragma mark 私有方法

void lock(dispatch_semaphore_t semaphore) {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

void unlock(dispatch_semaphore_t semaphore) {
    dispatch_semaphore_signal(semaphore);
}

- (nullable DownloadModel*)existsAtFinishedListWithTaskId:(NSString *)taskId {
    for (DownloadModel *task in self.finishedList) {
        if ([taskId isEqualToString:task.taskId]) {
            return task;
        }
    }
    return nil;
}

- (nullable DownloadModel *)existsAtDownloadingListWithTaskId:(NSString *)taskId {
    for (DownloadModel *task in self.downloadingList) {
        if ([taskId isEqualToString:task.taskId]) {
            return task;
        }
    }
    return nil;
}

- (nullable DownloadModel *)existsAtTaskListWithTaskId:(NSString *)taskId {
    for (DownloadModel *task in self.taskList) {
        if ([taskId isEqualToString:task.taskId]) {
            return task;
        }
    }
    return nil;
}

#pragma mark 公共方法

/// 删除任务
- (void)removeOperationWithTaskId:(NSString *)taskId {
    NSAssert(taskId, @"taskId不能为空");
    DownloadOperation *operation = [self.taskOperationMap objectForKey:taskId];
    if (operation) {
        [self.lock lock];
        [self.taskOperationMap removeObjectForKey:taskId];
        [operation cancel];
        [self.lock unlock];
    }
}

/// 添加任务
- (void)addOperationWithTaskId:(NSString *)taskId {
    DownloadModel *item = [self existsAtDownloadingListWithTaskId:taskId];
    DownloadOperation *operation = [self.taskOperationMap objectForKey:taskId];
    if (!operation) {
        operation = [[DownloadOperation alloc] initWithDownloadItem:item];
        __weak __typeof(self) weakSelf = self;
        operation.doneBlock = ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf removeOperationWithTaskId:taskId];
        };
        [self.lock lock];
        [self.taskOperationMap setValue:operation forKey:taskId];
        [self.taskQueue addOperation:operation];
        [self.lock unlock];
    }
}

/// 创建一个下载任务
- (void)startWithDownloadItem:(DownloadModel *)item {
    NSAssert(item, @"item不能为空");
    DownloadModel *downloadItem = item;
    if ([self existsAtFinishedListWithTaskId:item.taskId]) {
        downloadItem = [self existsAtFinishedListWithTaskId:item.taskId];
        NSLog(@"当前任务已经下载完成savepath:%@",downloadItem.savePath);
        NSLog(@"当前任务已经下载完成status:%zd",downloadItem.downloadStatus);
    }
    else if ([self existsAtDownloadingListWithTaskId:item.taskId]) {
        downloadItem = [self existsAtDownloadingListWithTaskId:item.taskId];
        NSLog(@"当前任务已经下载中列表savepath:%@",downloadItem.savePath);
        NSLog(@"当前任务已经下载中列表status:%zd",downloadItem.downloadStatus);
    }
    else {
        [[DownloadItemManager shareManager] addDownloadingItem:downloadItem];
        NSLog(@"新增任务URL:%@",downloadItem.fileURL);
        NSLog(@"新增任务status:%zd",downloadItem.downloadStatus);
    }
    
    [self resumeWithTaskId:downloadItem.taskId];
}

/// 暂停一个下载
- (void)pauseWithTaskId:(nonnull NSString *)taskId {
    NSAssert(taskId, @"taskId不能为空");
    DownloadModel *item = [self existsAtDownloadingListWithTaskId:taskId];
    NSAssert(item, @"未找到对应taskId的任务模型");
    item.downloadStatus = DownloadStatePaused;
    [self removeOperationWithTaskId:taskId];
}

/// 暂停全部下载
- (void)pauseAllDownloadTask {
    [self.taskQueue cancelAllOperations];
    for (DownloadModel *item in self.downloadingList) {
        [self pauseWithTaskId:item.taskId];
    }
}

/// 继续一个下载
- (void)resumeWithTaskId:(nonnull NSString *)taskId {
    NSAssert(taskId, @"taskId不能为空");
    if (self.reachabilityStatus == AFNetworkReachabilityStatusReachableViaWWAN && !self.allowsCellularAccess) {
        return;
    }
    DownloadModel *item = [self existsAtDownloadingListWithTaskId:taskId];
    if (item.downloadStatus != DownloadStateNotStarted) {
        item.downloadStatus = DownloadStateWaiting;
    }
    [self addOperationWithTaskId:taskId];
}
/// 继续全部下载
- (void)resumeAllDownloadTask {
    for (DownloadModel *item in self.downloadingList) {
        [self resumeWithTaskId:item.taskId];
    }
}
/// 删除一个下载
- (void)removeWithDownloadingTaskId:(nonnull NSString *)taskId {
    NSAssert(taskId, @"taskId不能为空");
    [[DownloadItemManager shareManager] removeDownloadingItem:taskId];
    [self removeOperationWithTaskId:taskId];
}
/// 删除一个下载完成的任务
- (void)removeWithFinishedTaskId:(NSString *)taskId {
    NSAssert(taskId, @"taskId不能为空");
    [[DownloadItemManager shareManager] removeFinishedItem:taskId];
}

/// 删除所有下载中的
- (void)removeAllDownloadingTask {
    [self.taskQueue cancelAllOperations];
    for (DownloadModel *item in self.downloadingList) {
        [self removeOperationWithTaskId:item.taskId];
    }
    [[DownloadItemManager shareManager] removeAllDownloadingItem];
}

/// 删除所有下载完成的任务
- (void)removeAllFinishedTask {
    [[DownloadItemManager shareManager] removeAllFinishedItem];
}

/// 删除所有下载
- (void)removeAllDownloadTask {
    [self removeAllDownloadingTask];
    [self removeAllFinishedTask];
}

/// 继续或暂停下载
- (void)resumeOrPauseWithTaskId:(NSString *)taskId {
    DownloadModel *item = [self existsAtDownloadingListWithTaskId:taskId];
    NSAssert(item, @"未找到正在下载中对应taskId的任务模型");
    if (item.downloadStatus == DownloadStateFailed || item.downloadStatus == DownloadStatePaused) {
        [self resumeWithTaskId:taskId];
    }
    else if (item.downloadStatus == DownloadStateWaiting || item.downloadStatus == DownloadStateDownloading || item.downloadStatus == DownloadStateNotStarted) {
        [self pauseWithTaskId:taskId];
    }
}

/// 根据下载任务标识获取下载任务
- (DownloadModel *)findDownloadItemWithTaskId:(NSString *)taskId {
    DownloadModel *item = [[DownloadItemManager shareManager] containsDownloadingItem:taskId];
    if (!item) {
        item = [[DownloadItemManager shareManager] containsFinishedItem:taskId];
    }
    return item;
}

- (void)saveDownloadDataWhenTerminate {
    [self pauseAllDownloadTask];
    [[DownloadItemManager shareManager] archiveList];
}

#pragma mark NSNotification

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self saveDownloadDataWhenTerminate];
}

#pragma mark getter && setter

- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads {
    _maxConcurrentDownloads = maxConcurrentDownloads;
    self.taskQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
}

- (NSMutableArray<DownloadModel *> *)taskList {
    return [DownloadItemManager shareManager].taskList;
}

- (NSMutableArray<DownloadModel *> *)downloadingList {
    return [DownloadItemManager shareManager].downloadingList;
}

- (NSMutableArray<DownloadModel *> *)finishedList {
    return [DownloadItemManager shareManager].finishedList;
}

@end
