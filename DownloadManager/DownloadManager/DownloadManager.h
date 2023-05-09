//
//  DownloadManager.h
//  DownloadManager
//
//  Created by Apple on 2023/3/2.
//

#import <Foundation/Foundation.h>
#import "DownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadManager : NSObject

/// 单列
+ (instancetype)shareManager;

// 当前下载队列的任务数量
@property (nonatomic, assign, readonly) NSUInteger downloadingCount;
/// 是否允许蜂窝网络下载 默认YES
@property (nonatomic, assign) BOOL allowsCellularAccess;
/// 最大任务数
@property (nonatomic, assign) NSInteger maxConcurrentDownloads;
/// 全部任务列表
@property (nonatomic, strong, readonly) NSMutableArray<DownloadModel *> *taskList;
/// 正在下载任务列表
@property (nonatomic, strong, readonly) NSMutableArray<DownloadModel *> *downloadingList;
/// 下载完成任务列表
@property (nonatomic, strong, readonly) NSMutableArray<DownloadModel *> *finishedList;

/// 开始一个下载任务
- (void)startWithDownloadItem:(nonnull DownloadModel *)item;
/// 暂停一个下载任务
- (void)pauseWithTaskId:(nonnull NSString *)taskId;
/// 删除一个下载中任务
- (void)removeWithDownloadingTaskId:(nonnull NSString *)taskId;
/// 删除一个下载完成的任务
- (void)removeWithFinishedTaskId:(nonnull NSString *)taskId;
/// 恢复一个下载任务
- (void)resumeWithTaskId:(nonnull NSString *)taskId;
/// 暂停所有下载任务
- (void)pauseAllDownloadTask;
/// 删除所有下载中任务
- (void)removeAllDownloadingTask;
/// 删除所有下载完成任务
- (void)removeAllFinishedTask;
/// 删除所有下载任务
- (void)removeAllDownloadTask;
/// 恢复所有下载任务
- (void)resumeAllDownloadTask;
/// 根据下载任务标识获取下载任务
- (nullable DownloadModel *)findDownloadItemWithTaskId:(NSString *)taskId;
/// 继续或暂停下载
- (void)resumeOrPauseWithTaskId:(nonnull NSString *)taskId;
/// 任务是否已完成
- (nullable DownloadModel*)existsAtFinishedListWithTaskId:(NSString *)taskId;
/// 任务是否在下载列表
- (nullable DownloadModel *)existsAtDownloadingListWithTaskId:(NSString *)taskId;
/// 任务是否在下载列表或完成列表
- (nullable DownloadModel *)existsAtTaskListWithTaskId:(NSString *)taskId;
/// App关闭时保存数据
- (void)saveDownloadDataWhenTerminate;
@end

NS_ASSUME_NONNULL_END
