//
//  YYDownloadSessionManager.h
//  YYDownloadManager
//
//  Created by Jonathan on 2023/3/3.
//

#import <Foundation/Foundation.h>
#import "YYDownloadTaskDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface YYDownloadSessionManager : NSObject
@property (nonatomic, copy, nullable) void(^completionHandler)(void);
@property (nonatomic, copy, readonly) NSString *identifier;
+ (nonnull instancetype)sharedManager;
/// 添加下载
- (void)addTask:(NSObject<YYDownloadTaskDelegate> *)task;
/// 暂停下载
- (void)pauseTask:(NSObject<YYDownloadTaskDelegate> *)task;
/// 暂停所有下载
- (void)pauseAllTask;
/// 删除下载
- (void)removeTask:(NSObject<YYDownloadTaskDelegate> *)task;
/// 删除所有下载
- (void)removeAllTask;
/// 继续下载
- (void)resumeTask:(NSObject<YYDownloadTaskDelegate> *)task;
/// 继续所有下载
- (void)resumeAllTask;

@end

NS_ASSUME_NONNULL_END
