//
//  DownloadTableViewCell.h
//  DownloadManager
//
//  Created by Apple on 2023/5/9.
//

#import <UIKit/UIKit.h>
#import "DownloadManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadTableViewCell : UITableViewCell
@property (nonatomic, strong) DownloadModel *dataModel;
@end

NS_ASSUME_NONNULL_END
