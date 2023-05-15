//
//  YYDownloadTaskDelegate.h
//  YYDownloadTaskDelegate
//
//  Created by Jonathan on 2023/3/2.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, YYDownloadStatus) {
    YYDownloadStatusUnknow,        // 未知状态
    YYDownloadStatusWaiting,       // 等待下载（等待下载队列中）
    YYDownloadStatusDownloading,   // 正在下载
    YYDownloadStatusPaused,        // 暂停下载
    YYDownloadStatusFailed,        // 下载失败
    YYDownloadStatusFinished,      // 下载完成
};

/// 下载状态改变通知
static NSString *const kDownloadStatusChangedNotification = @"kDownloadStatusChangedNotification";

/// 下载进度改变通知
static NSString *const kDownloadProgressUpdateNotification = @"kDownloadProgressUpdateNotification";


@protocol YYDownloadTaskDelegate <NSObject,NSCoding>

@required
/// 文件名
@property (nonatomic, copy) NSString *fileName;
/// 文件类型
@property (nonatomic, copy) NSString *fileType;
/// 下载地址
@property (nonatomic, copy) NSString *downloadURL;
/// 文件保存路径
@property (nonatomic, copy, readonly) NSString *filePath;
/// 恢复数据保存路径
@property (nonatomic, copy, readonly) NSString *resumeDataPath;
/// 请求下载头
@property (nonatomic, copy) NSDictionary *requestHeader;
/// 下载状态
@property (nonatomic, assign) YYDownloadStatus downloadStatus;
/// 下载进度，0.0 - 1.0
@property (nonatomic, assign) float downloadProgress;
/// 文件总大小
@property (nonatomic, assign) int64_t totalSize;
/// 已下载的文件大小
@property (nonatomic, assign) int64_t downloadedSize;
/// 下载的优先级
@property (nonatomic, assign) CGFloat queuePriority;
/// 下载任务
@property (nonatomic, copy) NSURLSessionDownloadTask *downloadTask;
/// 任务回调
@property (nonatomic, copy) void(^completionHander)(void);

@end

