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
+ (nonnull instancetype)sharedManager;
- (DownloadSessionDataTask *)downloadTaskWithDownloadItem:(DownloadModel *)item;
- (void)cancelTask:(DownloadSessionDataTask *)task;
- (void)cancelAllTask;
@end

NS_ASSUME_NONNULL_END
