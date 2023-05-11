//
//  DownloadSessionManager.h
//  DownloadManager
//
//  Created by Apple on 2023/3/3.
//

#import <Foundation/Foundation.h>
#import "DownloadModel.h"
#import "DownloadSessionDataTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadSessionManager : NSObject
@property (nonatomic, copy, nullable) void(^completionHandler)(void);
@property (nonatomic, copy, readonly) NSString *identifier;
+ (nonnull instancetype)sharedManager;
- (DownloadSessionDataTask *)downloadTaskWithDownloadItem:(DownloadModel *)item;
- (void)cancelTask:(DownloadSessionDataTask *)task;
- (void)cancelAllTask;
@end

NS_ASSUME_NONNULL_END
