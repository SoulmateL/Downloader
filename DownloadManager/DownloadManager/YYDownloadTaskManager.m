//
//  YYDownloadTaskManager.m
//  YYDownloadManager
//
//  Created by Jonathan on 2023/3/3.
//

#import "YYDownloadTaskManager.h"
#import "YYDownloadHelper.h"
#import "YYDownloadTask.h"

@interface YYDownloadTaskManager ()
/// 全部任务列表
@property (nonatomic, strong) NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *tasks;
/// 正在下载任务列表
@property (nonatomic, strong) NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *downloadingTasks;
/// 下载完成任务列表
@property (nonatomic, strong) NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *downloadedTasks;
/// 所有任务字典
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSObject<YYDownloadTaskDelegate> *> *taskMapper;
/// 操作列表的锁
@property (nonatomic, strong) NSLock *lock;

@end

@implementation YYDownloadTaskManager

+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    static YYDownloadTaskManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [YYDownloadTaskManager new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.tasks = [NSMutableArray array];
        self.lock = [[NSLock alloc] init];
        NSMutableArray *cacheTasks = [NSKeyedUnarchiver unarchiveObjectWithFile:[YYDownloadHelper downloadTaskCachePath]];
        if (cacheTasks.count) {
            [self.lock lock];
            [self.tasks addObjectsFromArray:cacheTasks];
            [self.lock unlock];
            [self updateTasks];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downloadStatusChanged:)
                                                     name:kDownloadStatusChangedNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark 私有方法

- (void)updateTasks {
    [self.lock lock];
    self.taskMapper = [NSMutableDictionary dictionary];
    self.downloadedTasks = [NSMutableArray array];
    self.downloadingTasks = [NSMutableArray array];
    for (NSObject<YYDownloadTaskDelegate> *task in self.tasks) {
        [self.taskMapper setObject:task forKey:task.downloadURL];
        if (task.downloadStatus == YYDownloadStatusFinished) {
            [self.downloadedTasks addObject:task];
        }
        else {
            [self.downloadingTasks addObject:task];
        }
    }
    [NSKeyedArchiver archiveRootObject:self.tasks toFile:[YYDownloadHelper downloadTaskCachePath]];
    [self.lock unlock];
}

#pragma mark NSNotification

- (void)downloadStatusChanged:(NSNotification *)notification {
    NSObject<YYDownloadTaskDelegate> *item = notification.object;
    if (item.downloadStatus == YYDownloadStatusFinished) {
        [self updateTasks];
    }
    
    [NSKeyedArchiver archiveRootObject:self.tasks toFile:[YYDownloadHelper downloadTaskCachePath]];
}

#pragma mark 公有方法

- (NSObject<YYDownloadTaskDelegate> *)taskWithDownloadURL:(NSString *)downloadURL {
    if (!downloadURL) return nil;
    NSObject<YYDownloadTaskDelegate> *task = [self.taskMapper objectForKey:downloadURL];
    return task;
}

- (void)addTask:(NSObject<YYDownloadTaskDelegate> *)task {
    if (!task) return;
    [self.lock lock];
    [self.tasks addObject:task];
    [self.lock unlock];
    [self updateTasks];
}

- (void)removeTask:(NSObject<YYDownloadTaskDelegate> *)task {
    if (!task) return;
    [YYDownloadHelper removeItemAtPath:task.filePath];
    [YYDownloadHelper removeItemAtPath:task.resumeDataPath];
    [self.lock lock];
    [self.tasks removeObject:task];
    [self.lock unlock];
    [self updateTasks];
}

- (void)removeAllDownloadedTask {
    [self.lock lock];
    [self.tasks enumerateObjectsUsingBlock:^(NSObject<YYDownloadTaskDelegate> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.downloadStatus == YYDownloadStatusFinished) {
            [YYDownloadHelper removeItemAtPath:obj.filePath];
            [YYDownloadHelper removeItemAtPath:obj.resumeDataPath];
            [self.tasks removeObject:obj];
        }
    }];
    [self.lock unlock];
    [self updateTasks];
}

- (void)removeAllDownloadingTask {
    [self.lock lock];
    [self.tasks enumerateObjectsUsingBlock:^(NSObject<YYDownloadTaskDelegate> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.downloadStatus != YYDownloadStatusFinished) {
            [YYDownloadHelper removeItemAtPath:obj.filePath];
            [YYDownloadHelper removeItemAtPath:obj.resumeDataPath];
            [self.tasks removeObject:obj];
        }
    }];
    [self.lock unlock];
    [self updateTasks];
}

- (void)removeAllTask {
    [self.lock lock];
    [self.tasks enumerateObjectsUsingBlock:^(NSObject<YYDownloadTaskDelegate> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [YYDownloadHelper removeItemAtPath:obj.filePath];
        [YYDownloadHelper removeItemAtPath:obj.resumeDataPath];
        [self.tasks removeObject:obj];
    }];
    [self.lock unlock];
    [self updateTasks];
}

- (NSArray<NSObject<YYDownloadTaskDelegate> *> *)TaskForStatus:(YYDownloadStatus)status {
    [self.lock lock];
    NSMutableArray *tasks = [NSMutableArray array];
    for (NSObject<YYDownloadTaskDelegate> *task in self.tasks) {
        if (task.downloadStatus == status) {
            [tasks addObject:task];
        }
    }
    [self.lock unlock];
    return [tasks copy];
}
    

- (void)archiveTasksData {
    [self.lock lock];
    [NSKeyedArchiver archiveRootObject:self.tasks toFile:[YYDownloadHelper downloadTaskCachePath]];
    [self.lock unlock];
}

@end
