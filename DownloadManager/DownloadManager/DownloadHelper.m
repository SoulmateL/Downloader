//
//  DownloadHelper.m
//  DownloadManager
//
//  Created by Apple on 2023/3/3.
//

#import "DownloadHelper.h"

@implementation DownloadHelper

+ (void)removeItemAtPath:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = NULL;
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:&error];
    }
    NSLog(@"path = %@",path);
    NSLog(@"removefile error = %@",error.localizedDescription);
}
+ (NSString *)createFileAtPath:(NSString *)path{
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
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"JJDownloadData"];
}

+ (NSString *)defaultDownloadSavePath {
    return [self createDirectoryAtPath:[[self documentDirectoryPath] stringByAppendingPathComponent:@"DownloadedCache"]];
}

+ (NSString *)downloadingTempCachePath {
    return [self createDirectoryAtPath:[[self documentDirectoryPath] stringByAppendingPathComponent:@"DownloadingTempCache"]];
}

+ (NSString *)taskListDirectoryPath {
    NSString *path = [self createDirectoryAtPath:[[self documentDirectoryPath] stringByAppendingPathComponent:@"TaskList"]];
    return path;
}

+ (NSString *)downloadingTaskListCachePath {
    return [[self taskListDirectoryPath] stringByAppendingPathComponent:@"DownloadingTask"];
}

+ (NSString *)finishedTaskListCachePath {
    return [[self taskListDirectoryPath] stringByAppendingPathComponent:@"finishedTask"];
}

@end
