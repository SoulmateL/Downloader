//
//  YYDownloadManager.h
//  YYDownloadManager
//
//  Created by Jonathan on 2023/3/2.
//

#import <Foundation/Foundation.h>
#import "YYDownloadTaskDelegate.h"
#import "YYDownloadConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface YYDownloadManager : NSObject

/// 单列
+ (instancetype)shareManager;
/// 配置文件
@property (nonatomic, strong) YYDownloadConfiguration *configuration;
/// 全部任务列表
@property (nonatomic, strong, readonly) NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *tasks;
/// 正在下载任务列表
@property (nonatomic, strong, readonly) NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *downloadingTasks;
/// 下载完成任务列表
@property (nonatomic, strong, readonly) NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *downloadedTasks;

/// 开始一个下载任务
- (void)startWithTask:(nonnull NSObject<YYDownloadTaskDelegate> *)task;
/// 暂停一个下载任务
- (void)pauseWithTask:(nonnull NSObject<YYDownloadTaskDelegate> *)task;
/// 删除一个下载任务
- (void)removeWithTask:(nonnull NSObject<YYDownloadTaskDelegate> *)task;
/// 恢复一个下载任务
- (void)resumeWithTask:(nonnull NSObject<YYDownloadTaskDelegate> *)task;

/// 暂停所有下载任务
- (void)pauseAllDownloadingTask;
/// 删除所有下载中任务
- (void)removeAllDownloadingTask;
/// 恢复所有下载任务
- (void)resumeAllDownloadingTask;

/// 删除所有下载完成任务
- (void)removeAllDownloadedTask;
/// 删除所有下载任务
- (void)removeAllDownloadTask;

/// 获取任务
- (nullable NSObject<YYDownloadTaskDelegate> *)taskWithDownloadURL:(NSString *)downloadURL;

/// 用户点击任务切换状态
- (void)changeTaskStatusWhenUserTaped:(nonnull NSObject<YYDownloadTaskDelegate> *)task;


@end

NS_ASSUME_NONNULL_END
