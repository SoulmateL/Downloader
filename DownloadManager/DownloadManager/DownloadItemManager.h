//
//  DownloadItemManager.h
//  DownloadManager
//
//  Created by Apple on 2023/3/3.
//

#import <Foundation/Foundation.h>
#import "DownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadItemManager : NSObject

/// 全部任务列表
@property (nonatomic, strong, readonly) NSMutableArray<DownloadModel *> *taskList;
/// 正在下载任务列表
@property (nonatomic, strong, readonly) NSMutableArray<DownloadModel *> *downloadingList;
/// 下载完成任务列表
@property (nonatomic, strong, readonly) NSMutableArray<DownloadModel *> *finishedList;

/// 单列
+ (instancetype)shareManager;

- (void)addDownloadingItem:(nonnull DownloadModel *)item;
- (void)completeDownloadingItem:(nonnull NSString *)taskId;
- (void)removeDownloadingItem:(nonnull NSString *)taskId;
- (void)removeAllDownloadingItem;
- (nullable DownloadModel *)containsDownloadingItem:(NSString *)taskId;

- (void)removeFinishedItem:(nonnull NSString *)taskId;
- (void)removeAllFinishedItem;
- (nullable DownloadModel *)containsFinishedItem:(nonnull NSString *)taskId;

- (void)archiveList;

@end

NS_ASSUME_NONNULL_END
