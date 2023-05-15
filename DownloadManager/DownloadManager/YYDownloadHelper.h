//
//  YYDownloadHelper.h
//  YYDownloadManager
//
//  Created by Jonathan on 2023/3/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YYDownloadHelper : NSObject

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


/// 写入文件
/// - Parameters:
///   - path: 文件路径
///   - error: 错误
+ (BOOL)writeToPath:(NSString *)path data:(NSData *)data;

/// 移动文件
/// - Parameters:
///   - srcURL: 移动文件路径
///   - dstURL: 目标文件路径
+ (BOOL)moveItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL;

/// 文件大小
/// - Parameter path: 文件路径
+ (unsigned long long)fileSizeForPath:(NSString *)path ;

/// 文件大小单位
/// - Parameter contentLength: 文件大小
+ (NSString *)calculateFileSize:(long long)contentLength;

/// 沙盒路径
+ (NSString *)documentDirectoryPath;

/// 默认下载地址
+ (NSString *)defaultDownloadSavePath;

/// 默认resumeData缓存地址
+ (NSString *)defaultDownloadResumeDataSavePath;

/// 下载模型列表
+ (NSString *)downloadTaskCachePath;


@end

NS_ASSUME_NONNULL_END
