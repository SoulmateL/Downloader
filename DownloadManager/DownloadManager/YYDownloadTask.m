//
//  YYDownloadTask.m
//  YYDownloadManager
//
//  Created by Jonathan on 2023/5/12.
//

#import "YYDownloadTask.h"
#import "YYDownloadHelper.h"
#import "YYDownloadConfiguration.h"
#include <CommonCrypto/CommonCrypto.h>

@implementation YYDownloadTask

- (instancetype)init {
    if (self = [super init]) {
        _downloadedSize = 0;
        _totalSize = 0;
        _downloadProgress = 0;
        _downloadStatus = YYDownloadStatusUnknow;
        _queuePriority = NSURLSessionTaskPriorityDefault;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.fileName forKey:@"fileName"];
    [coder encodeObject:self.fileType forKey:@"fileType"];
    [coder encodeObject:self.downloadURL forKey:@"downloadURL"];
    [coder encodeObject:self.requestHeader forKey:@"requestHeader"];
    [coder encodeObject:self.filePath forKey:@"filePath"];
    [coder encodeInt64:self.totalSize forKey:@"totalSize"];
    [coder encodeInt64:self.downloadedSize forKey:@"downloadedSize"];
    [coder encodeFloat:self.downloadProgress forKey:@"downloadProgress"];
    [coder encodeInteger:self.downloadStatus forKey:@"downloadStatus"];
    [coder encodeInteger:self.queuePriority forKey:@"queuePriority"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _fileName = [coder decodeObjectForKey:@"fileName"];
        _fileType = [coder decodeObjectForKey:@"fileType"];
        _downloadURL = [coder decodeObjectForKey:@"downloadURL"];
        _requestHeader = [coder decodeObjectForKey:@"requestHeader"];
        _filePath = [coder decodeObjectForKey:@"filePath"];
        _totalSize = [coder decodeInt64ForKey:@"totalSize"];
        _downloadedSize = [coder decodeInt64ForKey:@"downloadedSize"];
        _downloadProgress = [coder decodeFloatForKey:@"downloadProgress"];
        _downloadStatus = [coder decodeIntegerForKey:@"downloadStatus"];
        _queuePriority = [coder decodeIntegerForKey:@"queuePriority"];
    }
    return self;
}

#pragma mark getter && setter

- (float)downloadProgress {
    _downloadProgress = 1.0 * self.downloadedSize / self.totalSize;
    if (!isnan(_downloadProgress)) {
        return _downloadProgress;
    }
    return 0;
}

- (NSString *)filePath {
    if (!_filePath) {
        _filePath = [[YYDownloadConfiguration defaultConfiguration].saveRootPath stringByAppendingPathComponent:self.fileName];
    }
    return _filePath;
}

- (NSString *)resumeDataPath {
    return [[YYDownloadHelper defaultDownloadResumeDataSavePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.data",[self.fileName stringByDeletingPathExtension]]];
}

- (NSString *)fileName {
    if (!_fileName) {
        _fileName = [self.downloadURL lastPathComponent];
    }
    return _fileName;
}

- (void)setDownloadStatus:(YYDownloadStatus)downloadStatus {
    if (_downloadStatus != downloadStatus) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadStatusChangedNotification object:self];
        });
    }
    _downloadStatus = downloadStatus;
}

@end
