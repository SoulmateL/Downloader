//
//  YYDownloadConfiguration.h
//  YYDownloadManager
//
//  Created by Jonathan on 2023/5/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YYDownloadConfiguration : NSObject
/// 是否允许蜂窝网络下载
@property (nonatomic, assign) BOOL allowsCellularAccess;
/// 请求超时时间
@property (nonatomic, assign) NSTimeInterval timeoutIntervalForRequest;
/// 最大并行任务数
@property (nonatomic, assign) NSInteger maxTaskCount;
/// 文件保存根路径
@property (nonatomic, copy, nullable) NSString *saveRootPath;

+ (YYDownloadConfiguration *)defaultConfiguration;

@end

NS_ASSUME_NONNULL_END
