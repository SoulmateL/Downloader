//
//  DownloadModel.m
//  DownloadModel
//
//  Created by Apple on 2023/3/2.
//

#import "DownloadModel.h"
#import "DownloadHelper.h"
#include <CommonCrypto/CommonCrypto.h>

NSString *const kDownloadStatusChangedNotification = @"kDownloadStatusChangedNotification";

NSString *const kDownloadProgressUpdateNotification = @"kDownloadProgressUpdateNotification";

@implementation DownloadModel

- (instancetype)init {
    if (self = [super init]) {
        _downloadedSize = 0;
        _totalSize = 0;
        _downloadProgress = 0;
        _downloadStatus = DownloadStateNotStarted;
        _queuePriority = NSOperationQueuePriorityNormal;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.taskId forKey:@"taskId"];
    [coder encodeObject:self.fileName forKey:@"fileName"];
    [coder encodeObject:self.fileType forKey:@"fileType"];
    [coder encodeObject:self.fileURL forKey:@"fileURL"];
    [coder encodeObject:self.httpHeaders forKey:@"httpHeaders"];
    [coder encodeObject:self.savePath forKey:@"savePath"];
    [coder encodeObject:self.resumeDataPath forKey:@"resumeDataPath"];
    [coder encodeInt64:self.totalSize forKey:@"totalSize"];
    [coder encodeInt64:self.downloadedSize forKey:@"downloadedSize"];
    [coder encodeFloat:self.downloadProgress forKey:@"downloadProgress"];
    [coder encodeInteger:self.downloadStatus forKey:@"downloadStatus"];
    [coder encodeInteger:self.queuePriority forKey:@"queuePriority"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _taskId = [coder decodeObjectForKey:@"taskId"];
        _fileName = [coder decodeObjectForKey:@"fileName"];
        _fileType = [coder decodeObjectForKey:@"fileType"];
        _fileURL = [coder decodeObjectForKey:@"fileURL"];
        _httpHeaders = [coder decodeObjectForKey:@"httpHeaders"];
        _savePath = [coder decodeObjectForKey:@"savePath"];
        _resumeDataPath = [coder decodeObjectForKey:@"resumeDataPath"];
        _totalSize = [coder decodeInt64ForKey:@"totalSize"];
        _downloadedSize = [coder decodeInt64ForKey:@"downloadedSize"];
        _downloadProgress = [coder decodeFloatForKey:@"downloadProgress"];
        _downloadStatus = [coder decodeIntegerForKey:@"downloadStatus"];
        _queuePriority = [coder decodeIntegerForKey:@"queuePriority"];
    }
    return self;
}

- (void)removeData {
    [DownloadHelper removeItemAtPath:self.savePath];
}

- (void)removeResumeData {
    [DownloadHelper removeItemAtPath:self.resumeDataPath];
}

#pragma mark getter && setter 

- (float)downloadProgress {
    _downloadProgress = 1.0 * self.downloadedSize / self.totalSize;
    if (!isnan(_downloadProgress)) {
        return _downloadProgress;
    }
    return 0;
}

- (double)downloadSpeed {
    NSTimeInterval downloadTime = [[NSDate date] timeIntervalSinceDate:self.creationDate];
    if (downloadTime == 0) {
        return 0;
    }
    double speed = (double)self.downloadedSize / 1024.0 / 1024.0 / downloadTime;
    return speed;
}

- (NSTimeInterval)remainingTime {
    double speed = [self downloadSpeed];
    if (speed == 0) {
        return -1;
    }
    double remainingSize = self.totalSize - self.downloadedSize;
    NSTimeInterval remainingTime = remainingSize / 1024.0 / 1024.0 / speed;
    return remainingTime;
}

- (NSString *)extension {
    return [self.savePath pathExtension];
}

- (NSDate *)modificationDate {
    return [self.attributes objectForKey:NSFileModificationDate];
}

- (NSDate *)creationDate {
    return [self.attributes objectForKey:NSFileCreationDate];
}

- (NSDate *)accessDate {
    return [self.attributes objectForKey:NSFileModificationDate];
}

- (NSDictionary *)attributes {
    NSError *error;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.savePath error:&error];
    if (error) {
        NSLog(@"获取文件属性失败: %@", error);
        return nil;
    }
    return attributes;
}

- (NSString *)savePath {
    return [[DownloadHelper defaultDownloadSavePath] stringByAppendingPathComponent:self.fileName];
}

- (NSString *)resumeDataPath {
    return [[DownloadHelper defaultDownloadSavePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",[self.fileName stringByDeletingPathExtension]]];
}

- (NSString *)fileName {
    if (!_fileName) {
        _fileName = [self.fileURL lastPathComponent];
    }
    return _fileName;
}

- (NSString *)taskId {
    if (!_taskId) {
        _taskId = [self md5String:[self.fileURL dataUsingEncoding:NSUTF8StringEncoding]];
    }
    return _taskId;
}

- (void)setDownloadStatus:(DownloadState)downloadStatus {
    if (_downloadStatus != downloadStatus) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadStatusChangedNotification object:self];
        });
    }
    _downloadStatus = downloadStatus;
}

- (NSString *)md5String:(NSData *)data {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end
