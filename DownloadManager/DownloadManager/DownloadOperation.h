//
//  DownloadOperation.h
//  DownloadManager
//
//  Created by Apple on 2023/3/3.
//

#import <Foundation/Foundation.h>
#import "DownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadOperation : NSOperation
@property (nonatomic, strong, readonly) DownloadModel *downloadItem;
@property (nonatomic, copy) dispatch_block_t doneBlock;
- (instancetype)initWithDownloadItem:(DownloadModel *)item;

@end

NS_ASSUME_NONNULL_END
