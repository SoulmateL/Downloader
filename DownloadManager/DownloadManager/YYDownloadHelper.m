//
//  YYDownloadHelper.m
//  YYDownloadManager
//
//  Created by Jonathan on 2023/3/3.
//

#import "YYDownloadHelper.h"

@implementation YYDownloadHelper

+ (void)removeItemAtPath:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = NULL;
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:&error];
    }
    if (error) {
        NSLog(@"path = %@",path);
        NSLog(@"removefile error = %@",error.localizedDescription);
    }
}
+ (NSString *)createFileAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:path]) {
        [fileManager createFileAtPath:path contents:nil attributes:nil];
    }
    return path;
}

+ (NSString *)createDirectoryAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if(![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if(error) {
            NSLog(@"%@",[error description]);
        }
    }
    return path;
}

+ (BOOL)writeToPath:(NSString *)path data:(nonnull NSData *)data {
    if (![self fileExistsAtPath:path]) {
        [self createDirectoryAtPath:[path stringByDeletingLastPathComponent]];
    }
    NSError *error;
    if ([data writeToFile:path options:NSDataWritingAtomic error:&error]) {
        return YES;
    }
    else {
        NSLog(@"%@",error.description);
        return NO;
    }
}

+ (BOOL)moveItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    if (![self fileExistsAtPath:dstURL.path]) {
        [self createDirectoryAtPath:[dstURL.path stringByDeletingLastPathComponent]];
    }
    NSError *error;
    if ([[NSFileManager defaultManager] moveItemAtURL:srcURL toURL:dstURL error:&error]) {
        return YES;
    }
    else {
        NSLog(@"%@",error.description);
        return NO;
    }
}

+ (BOOL)fileExistsAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}

+ (unsigned long long)fileSizeForPath:(NSString *)path {
    unsigned long long fileLength = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDic) {
            fileLength = [fileDic fileSize];
        }
    }
    return fileLength;
}

+ (NSString *)calculateFileSize:(long long)contentLength {
    float len = 0.f;
    if (contentLength >= pow(1024, 3)) {
        len =  (contentLength / pow(1024, 3));
        return [NSString stringWithFormat:@"%.1fG",len];
    }else if (contentLength >= pow(1024, 2)) {
        len = (contentLength / pow(1024, 2));
        return [NSString stringWithFormat:@"%.1fM",len];
    }else if (contentLength >= 1024) {
        len = (contentLength / 1024);
        return [NSString stringWithFormat:@"%.1fK",len];
    }else {
        len = contentLength;
        return [NSString stringWithFormat:@"%.fB",len];
    }
}

+ (NSString *)documentDirectoryPath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"YYDownload"];
}

+ (NSString *)defaultDownloadSavePath {
    return [[self documentDirectoryPath] stringByAppendingPathComponent:@"YYDownload"];
}

+ (NSString *)defaultDownloadResumeDataSavePath {
    return [[self documentDirectoryPath] stringByAppendingPathComponent:@"YYResumeDownload"];
}

+ (NSString *)downloadTaskCachePath {
    NSString *path = [[self documentDirectoryPath] stringByAppendingPathComponent:@"tasks.data"];
    return path;
}

@end
