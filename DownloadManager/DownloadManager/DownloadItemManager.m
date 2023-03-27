//
//  DownloadItemManager.m
//  DownloadManager
//
//  Created by Apple on 2023/3/3.
//

#import "DownloadItemManager.h"
#import "DownloadHelper.h"

@interface DownloadItemManager ()
/// 全部任务列表
@property (nonatomic, strong) NSMutableArray<DownloadModel *> *taskList;
/// 正在下载任务列表
@property (nonatomic, strong) NSMutableArray<DownloadModel *> *downloadingList;
/// 下载完成任务列表
@property (nonatomic, strong) NSMutableArray<DownloadModel *> *finishedList;
/// 操作列表的锁
@property (nonatomic, strong) NSLock *lock;

@end

@implementation DownloadItemManager

+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    static DownloadItemManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [DownloadItemManager new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        [self.lock lock];
        _downloadingList = [self taskListWithPath:[DownloadHelper downloadingTaskListCachePath]];
        _finishedList = [self taskListWithPath:[DownloadHelper finishedTaskListCachePath]];
        [self.lock unlock];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downloadCompleted:)
                                                     name:kDownloadStatusChangedNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark 私有方法

- (NSMutableArray *)taskListWithPath:(NSString *)path {
    NSMutableArray *list = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    if (!list) {
        list = [NSMutableArray array];
    }
    return list;
}

- (void)archiveDownloadingList {
    [NSKeyedArchiver archiveRootObject:self.downloadingList toFile:[DownloadHelper downloadingTaskListCachePath]];
}

- (void)archiveFinishedList {
    [NSKeyedArchiver archiveRootObject:self.finishedList toFile:[DownloadHelper finishedTaskListCachePath]];
}

- (void)removeItemWithTaskId:(nullable NSString *)taskId list:(NSMutableArray<DownloadModel *> *)list {
    [list enumerateObjectsUsingBlock:^(DownloadModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.taskId isEqualToString:taskId]) {
            [list removeObject:obj];
            *stop = YES;
        }
    }];
}

- (nullable DownloadModel *)downloadItemWithTaskId:(nullable NSString *)taskId list:(NSMutableArray<DownloadModel *> *)list {
    DownloadModel *downloadItem = nil;
    for (DownloadModel *item in list) {
        if ([item.taskId isEqualToString:taskId]) {
            downloadItem = item;
            break;
        }
    }
    return downloadItem;
}

#pragma mark NSNotification

- (void)downloadCompleted:(NSNotification *)notification {
    DownloadModel *item = notification.object;
    if (item.downloadStatus == DownloadStateFinished) {
        [self completeDownloadingItem:item.taskId];
    }
}

#pragma mark 公有方法

- (void)addDownloadingItem:(DownloadModel *)item {
    NSAssert(item, @"item不能为空");
    [self.lock lock];
    [self.downloadingList addObject:item];
    [self archiveDownloadingList];
    [self.lock unlock];
}

- (void)completeDownloadingItem:(nonnull NSString *)taskId {
    NSAssert(taskId, @"taskId不能为空");
    DownloadModel *item = [self downloadItemWithTaskId:taskId list:self.downloadingList];
    NSAssert(item, @"未找到对应taskId的任务");
    [self.lock lock];
    [self.downloadingList removeObject:item];
    [self archiveDownloadingList];
    [self.finishedList addObject:item];
    [self archiveFinishedList];
    [self.lock unlock];
}

- (void)removeDownloadingItem:(nonnull NSString *)taskId {
    NSAssert(taskId, @"taskId不能为空");
    DownloadModel *item = [self downloadItemWithTaskId:taskId list:self.downloadingList];
    NSAssert(item, @"未找到对应taskId的任务");
    [item removeData];
    [self.lock lock];
    [self.downloadingList removeObject:item];
    [self archiveDownloadingList];
    [self.lock unlock];
}

- (void)removeAllDownloadingItem {
    for (DownloadModel *item in self.downloadingList) {
        [item removeData];
    }
    [self.lock lock];
    [self.downloadingList removeAllObjects];
    [self archiveDownloadingList];
    [self.lock unlock];
}

- (DownloadModel *)containsDownloadingItem:(NSString *)taskId {
    for (DownloadModel *task in self.downloadingList) {
        if ([task.taskId isEqualToString:taskId]) {
            return task;
        }
    }
    return nil;
}

- (void)removeFinishedItem:(nonnull NSString *)taskId {
    NSAssert(taskId, @"taskId不能为空");
    DownloadModel *item = [self downloadItemWithTaskId:taskId list:self.finishedList];
    NSAssert(item, @"未找到对应taskId的任务");

    [item removeData];
    [self.lock lock];
    [self.finishedList removeObject:item];
    [self archiveFinishedList];
    [self.lock unlock];
}

- (void)removeAllFinishedItem {
    for (DownloadModel *item in self.finishedList) {
        [item removeData];
    }
    [self.lock lock];
    [self.finishedList removeAllObjects];
    [self archiveFinishedList];
    [self.lock unlock];
}

- (DownloadModel *)containsFinishedItem:(NSString *)taskId {
    for (DownloadModel *task in self.finishedList) {
        if ([task.taskId isEqualToString:taskId]) {
            return task;
        }
    }
    return nil;
}

- (void)archiveList {
    [self.lock lock];
    [self archiveDownloadingList];
    [self archiveFinishedList];
    [self.lock unlock];
}

#pragma mark getter && setter

- (NSMutableArray<DownloadModel *> *)taskList {
    NSMutableArray *list = [NSMutableArray arrayWithArray:self.downloadingList];
    [list addObjectsFromArray:self.finishedList];
    return list;
}

@end
