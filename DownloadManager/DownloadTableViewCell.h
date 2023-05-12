//
//  DownloadTableViewCell.h
//  YYDownloadManager
//
//  Created by Jonathan on 2023/5/9.
//

#import <UIKit/UIKit.h>
#import "YYDownloadManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadTableViewCell : UITableViewCell
@property (nonatomic, strong) NSObject<YYDownloadTaskDelegate> *dataModel;
@end

NS_ASSUME_NONNULL_END
