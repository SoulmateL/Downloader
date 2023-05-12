//
//  YYDownloadTaskManager.h
//  YYDownloadManager
//
//  Created by Jonathan on 2023/3/3.
//

#import <Foundation/Foundation.h>
#import "YYDownloadTask.h"
#import "YYDownloadTaskDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface YYDownloadTaskManager : NSObject

/// 全部任务列表
@property (nonatomic, strong, readonly) NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *tasks;
/// 下载任务列表
@property (nonatomic, strong, readonly) NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *downloadingTasks;
/// 下载完成任务列表
@property (nonatomic, strong, readonly) NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *downloadedTasks;
/// 所有任务字典
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *,NSObject<YYDownloadTaskDelegate> *> *taskMapper;
/// 单列
+ (instancetype)shareManager;

/// 添加任务
- (void)addTask:(nonnull NSObject<YYDownloadTaskDelegate> *)task;
/// 删除任务
- (void)removeTask:(nonnull NSObject<YYDownloadTaskDelegate> *)task;
/// 删除所有下载列表任务
- (void)removeAllDownloadingTask;
/// 删除所有下载完成任务
- (void)removeAllDownloadedTask;
/// 删除所有任务
- (void)removeAllTask;
/// 获取任务
- (nullable NSObject<YYDownloadTaskDelegate> *)taskWithDownloadURL:(NSString *)downloadURL;
/// 保存任务列表
- (void)archiveTasksData;
/// 获取指定状态的任务
- (NSArray<NSObject<YYDownloadTaskDelegate> *> *)TaskForStatus:(YYDownloadStatus)status;

@end

NS_ASSUME_NONNULL_END
