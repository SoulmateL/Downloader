//
//  DownloadHelper.h
//  DownloadManager
//
//  Created by Apple on 2023/3/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloadHelper : NSObject

/// 删除文件
/// - Parameter path: 文件路径
+ (void)removeItemAtPath:(NSString *)path;

/// 创建文件
/// - Parameter path: 文件路径
+ (NSString *)createFileAtPath:(NSString *)path;

/// 创建文件夹
/// - Parameter path: 文件夹路径
+ (NSString *)createDirectoryAtPath:(NSString *)path;

/// 文件是否存在
/// - Parameter path: 文件路径
+ (BOOL)fileExistsAtPath:(NSString *)path;

/// 文件大小
/// - Parameter path: 文件路径
+ (unsigned long long)fileSizeForPath:(NSString *)path ;

/// 文件大小单位
/// - Parameter contentLength: 文件大小
+ (NSString *)calculateFileSize:(long long)contentLength;

/// 下载中的临时缓存文件
+ (NSString *)downloadingTempCachePath;

/// 沙盒路径
+ (NSString *)documentDirectoryPath;

/// 默认下载地址
+ (NSString *)defaultDownloadSavePath;

/// 下载任务文件夹路径
+ (NSString *)taskListDirectoryPath;

/// 下载中的模型列表
+ (NSString *)downloadingTaskListCachePath;

/// 下载完成的模型列表
+ (NSString *)finishedTaskListCachePath;

@end

NS_ASSUME_NONNULL_END
