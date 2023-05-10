//
//  DownloadResumeData.h
//  DownloadManager
//
//  Created by Apple on 2023/5/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloadResumeData : NSObject
@property (nonatomic, copy) NSString *downloadUrl;
@property (nonatomic, strong) NSMutableURLRequest *currentRequest;
@property (nonatomic, strong) NSMutableURLRequest *originalRequest;
@property (nonatomic, assign) NSInteger downloadSize;
@property (nonatomic, copy) NSString *resumeTag;
@property (nonatomic, assign) NSInteger resumeInfoVersion;
@property (nonatomic, strong) NSDate *downloadDate;
@property (nonatomic, copy) NSString *tempName;
@property (nonatomic, copy) NSString *resumeRange;

- (instancetype)initWithResumeData:(NSData *)resumeData;

+ (NSURLSessionDownloadTask *)downloadTaskWithCorrectResumeData:(NSData *)resumeData urlSession:(NSURLSession *)urlSession;

/**
 清除 NSURLSessionResumeByteRange 字段
 修正iOS11.0 iOS11.1 多次暂停继续 文件大小不对的问题(iOS11.2官方已经修复)
 
 @param resumeData 原始resumeData
 @return 清除后resumeData
 */
+ (NSData *)cleanResumeData:(NSData *)resumeData;
@end

NS_ASSUME_NONNULL_END
