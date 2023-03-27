//
//  DownloadSessionDataTask.h
//  DownloadManager
//
//  Created by Apple on 2023/3/9.
//

#import <Foundation/Foundation.h>
#import "DownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadSessionDataTask : NSObject
@property (nonatomic, copy, readonly) NSString *taskId;
@property (nonatomic, strong, readonly) DownloadModel *downloadItem;
@property (nonatomic, copy) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong, nullable) NSOutputStream *stream;//输出流
@property (nonatomic, copy) void(^completionHander)(NSError *error);
- (instancetype)initWithDownloadItem:(DownloadModel *)item;
@end

NS_ASSUME_NONNULL_END
