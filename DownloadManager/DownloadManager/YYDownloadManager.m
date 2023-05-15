//
//  YYDownloadManager.m
//  YYDownloadManager
//
//  Created by Jonathan on 2023/3/2.
//

#import "YYDownloadManager.h"
#import "YYDownloadTaskManager.h"
#import "YYDownloadSessionManager.h"

@interface YYDownloadManager ()

@end

@implementation YYDownloadManager


+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    static YYDownloadManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.configuration = [YYDownloadConfiguration defaultConfiguration];
    }
    return self;
}

#pragma mark 公共方法

- (void)startWithTask:(NSObject<YYDownloadTaskDelegate> *)task {
    [[YYDownloadSessionManager sharedManager] addTask:task];
}

- (void)pauseWithTask:(NSObject<YYDownloadTaskDelegate> *)task {
    [[YYDownloadSessionManager sharedManager] pauseTask:task];
}

- (void)removeWithTask:(nonnull NSObject<YYDownloadTaskDelegate> *)task {
    [[YYDownloadSessionManager sharedManager] removeTask:task];
}

- (void)resumeWithTask:(nonnull NSObject<YYDownloadTaskDelegate> *)task {
    [[YYDownloadSessionManager sharedManager] resumeTask:task];
}

- (void)pauseAllDownloadingTask {
    [[YYDownloadSessionManager sharedManager] pauseAllTask];
}

- (void)resumeAllDownloadingTask {
    [[YYDownloadSessionManager sharedManager] resumeAllTask];
}

- (void)removeAllDownloadingTask {
    [[YYDownloadSessionManager sharedManager] removeAllTask];
}

- (void)removeAllDownloadedTask {
    [[YYDownloadTaskManager shareManager] removeAllDownloadedTask];
}

- (void)removeAllDownloadTask {
    [self removeAllDownloadedTask];
    [self removeAllDownloadingTask];
}

- (nullable NSObject<YYDownloadTaskDelegate> *)taskWithDownloadURL:(NSString *)downloadURL {
    return [[YYDownloadTaskManager shareManager] taskWithDownloadURL:downloadURL];
}

- (void)changeTaskStatusWhenUserTaped:(nonnull NSObject<YYDownloadTaskDelegate> *)task {
    if (task.downloadStatus == YYDownloadStatusDownloading || task.downloadStatus == YYDownloadStatusWaiting) {
        [self pauseWithTask:task];
    }
    else if (task.downloadStatus == YYDownloadStatusPaused || task.downloadStatus == YYDownloadStatusFailed){
        [self resumeWithTask:task];
    }
}

#pragma mark getter && setter

- (NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *)tasks {
    return [YYDownloadTaskManager shareManager].tasks;
}

- (NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *)downloadingTasks {
    return [YYDownloadTaskManager shareManager].downloadingTasks;
}

- (NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *)downloadedTasks {
    return [YYDownloadTaskManager shareManager].downloadedTasks;
}

@end
