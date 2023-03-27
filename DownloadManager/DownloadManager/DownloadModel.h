//
//  DownloadModel.h
//  DownloadModel
//
//  Created by Apple on 2023/3/2.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DownloadState) {
    DownloadStateNotStarted,    // 未开始下载
    DownloadStateWaiting,       // 等待下载（等待下载队列中）
    DownloadStateDownloading,   // 正在下载
    DownloadStatePaused,        // 暂停下载
    DownloadStateFailed,        // 下载失败
    DownloadStateFinished,      // 下载完成
};

/// 下载状态改变通知
UIKIT_EXTERN NSNotificationName const kDownloadStatusChangedNotification;
/// 下载进度改变通知
UIKIT_EXTERN NSNotificationName const kDownloadProgressUpdateNotification;


@interface DownloadModel : NSObject <NSCoding>

@property (nonatomic, copy) NSString *taskId;         // 下载任务的唯一标识符
@property (nonatomic, copy) NSString *fileName;         // 文件名
@property (nonatomic, copy) NSString *fileType;         // 文件类型
@property (nonatomic, copy) NSString *fileURL;          // 下载链接
@property (nonatomic, copy) NSString *savePath;         // 文件保存路径
@property (nonatomic, copy) NSDictionary *httpHeaders;         // 请求下载头
@property (nonatomic, assign) DownloadState downloadStatus;   // 下载状态
@property (nonatomic, assign) float downloadProgress;        // 下载进度，0.0 - 1.0
@property (nonatomic, assign) int64_t totalSize;        // 文件总大小
@property (nonatomic, assign) int64_t downloadedSize;        // 下载的文件大小
@property (nonatomic, assign) NSOperationQueuePriority queuePriority;        // 下载的优先级
/// ------- 下载开始后才可访问 ------------

@property (nonatomic, assign, readonly) double downloadSpeed;                 // 下载速度
@property (nonatomic, assign, readonly) NSTimeInterval remainingTime;        // 剩余下载时间
@property (nonatomic, copy, readonly) NSString *extension;  // 文件扩展名
@property (nonatomic, copy, readonly) NSDate *modificationDate;  // 修改时间
@property (nonatomic, copy, readonly) NSDate *creationDate;  // 创建时间
@property (nonatomic, copy, readonly) NSDate *accessDate;  // 访问时间
@property (nonatomic, copy, readonly) NSDictionary *attributes;  // 属性列表

- (void)removeData;

@end
