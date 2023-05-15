//
//  YYDownloadConfiguration.m
//  YYDownloadManager
//
//  Created by Jonathan on 2023/5/12.
//

#import "YYDownloadConfiguration.h"
#import "YYDownloadHelper.h"
#import "YYDownloadSessionManager.h"

@implementation YYDownloadConfiguration

+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    static YYDownloadConfiguration *instance;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

+ (YYDownloadConfiguration *)defaultConfiguration {
    return [YYDownloadConfiguration shareManager];
}

- (instancetype)init {
    if (self = [super init]) {
        self.allowsCellularAccess = YES;
        self.timeoutIntervalForRequest = 60;
        self.maxTaskCount = 2;
        self.saveRootPath = [YYDownloadHelper defaultDownloadSavePath];
    }
    return self;
}

@end
