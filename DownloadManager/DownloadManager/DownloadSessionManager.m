//
//  DownloadSessionManager.m
//  DownloadManager
//
//  Created by Apple on 2023/3/3.
//

#import "DownloadSessionManager.h"
#import "DownloadHelper.h"
#import "DownloadResumeData.h"

// 后台下载任务标识
static NSString *const kDownloadBackgroundSessionIdentifier = @"com.jonathan.download.backgroundidentifier";

@interface DownloadSessionManager ()<NSURLSessionDownloadDelegate>
/// 任务会话
@property (nonatomic, strong) NSURLSession *sessionManager;
/// 所有任务回调信息map
@property (nonatomic, strong) NSMutableDictionary<NSURLSessionDownloadTask *,DownloadSessionDataTask *> *allTaskMap;
/// 锁
@property (nonatomic, strong) NSLock *lock;

@end

@implementation DownloadSessionManager

- (void)dealloc {
    [self cancelAllTask];
}

+ (nonnull instancetype)sharedManager{
    static dispatch_once_t once;
    static DownloadSessionManager *instance;
    dispatch_once(&once, ^{
        instance = [DownloadSessionManager new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self defaultConfiguration];
    }
    return self;
}

/// 默认配置
- (void)defaultConfiguration {
    _lock = [[NSLock alloc] init];
    _allTaskMap = [NSMutableDictionary dictionary];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kDownloadBackgroundSessionIdentifier];
    configuration.allowsCellularAccess = YES;
    configuration.timeoutIntervalForRequest = 30;
    configuration.HTTPMaximumConnectionsPerHost = 60;
    configuration.sessionSendsLaunchEvents = YES;
    _sessionManager = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    [_sessionManager getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        for (NSURLSessionDownloadTask *task in downloadTasks) {
            NSLog(@"~~~~~~%zd",task.state);
            NSLog(@"~~~~~~%@",task.taskDescription);
            [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                [self saveResumeData:resumeData resumePath:task.taskDescription];
            }];
        }
    }];
}

#pragma mark public method

- (void)cancelAllTask{
    [self saveResumeData];
    [self.sessionManager invalidateAndCancel];
}

- (DownloadSessionDataTask *)downloadTaskWithDownloadItem:(DownloadModel *)item {
    DownloadSessionDataTask *task = [[DownloadSessionDataTask alloc] initWithDownloadItem:item];
    NSURL *URL = [NSURL URLWithString:item.fileURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setAllHTTPHeaderFields:item.httpHeaders];
    NSData *resumeData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:item.resumeDataPath]];
    if (resumeData) {
        task.dataTask = [DownloadResumeData downloadTaskWithCorrectResumeData:resumeData urlSession:self.sessionManager];
    }
    else {
        task.dataTask = [self.sessionManager downloadTaskWithRequest:request];
    }
    task.dataTask.taskDescription = item.resumeDataPath;
    if (!task.dataTask) return nil;
    [self.lock lock];
    [self.allTaskMap setObject:task forKey:task.dataTask];
    [self.lock unlock];
    [task.dataTask resume];
    return task;
}

- (void)cancelTask:(DownloadSessionDataTask *)task {
    if (!task) return;
    [task.dataTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        NSLog(@"~~~~~~%@",resumeData);
        [self saveResumeData:resumeData resumePath:task.downloadItem.resumeDataPath];
    }];
    [self.lock lock];
    [self.allTaskMap removeObjectForKey:task.dataTask];
    [self.lock unlock];
}

- (void)saveResumeData:(NSData *)resumeData resumePath:(NSString *)resumePath {
    if (!resumeData) return;
    NSURL *resumeFilePath = [NSURL fileURLWithPath:resumePath];
    [resumeFilePath setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    NSError *writeError;
    if ([resumeData writeToURL:resumeFilePath options:NSDataWritingAtomic error:&writeError]) {
        NSLog(@"写入resumeData:%@",resumePath);
    }
    else {
        NSLog(@"%@",writeError.description);
    }
}

- (void)saveResumeData {
    for (DownloadSessionDataTask *task in self.allTaskMap.allValues) {
        [task.dataTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            NSLog(@"~~~~~~%@",resumeData);
            [self saveResumeData:resumeData resumePath:task.downloadItem.resumeDataPath];
        }];
    }
}


#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    DownloadSessionDataTask *task = [self.allTaskMap objectForKey:downloadTask];
    if (!task) return;
    DownloadModel *downloadItem = task.downloadItem;
    if (!downloadItem) return;
    int64_t expectedContentLength = downloadTask.response.expectedContentLength;
    downloadItem.downloadedSize = totalBytesWritten;
    downloadItem.totalSize = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite:expectedContentLength;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadProgressUpdateNotification object:downloadItem];
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    DownloadSessionDataTask *task = [self.allTaskMap objectForKey:downloadTask];
    if (!task) return;
    DownloadModel *downloadItem = task.downloadItem;
    if (!downloadItem) return;
    NSError *error;
    if ([[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:downloadItem.savePath] error:&error]) {
        [downloadItem removeResumeData];
        NSLog(@"下载完成:taskId:%@\n path:%@",downloadItem.taskId,downloadItem.savePath);
    }
    else {
        NSLog(@"%@",error.description);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDownloadTask *)downloadTask didCompleteWithError:(NSError *)error {
    DownloadSessionDataTask *task = [self.allTaskMap objectForKey:downloadTask];
    if (!task) return;
    DownloadModel *downloadItem = task.downloadItem;
    if (!downloadItem) return;
    if (error) {
        NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0f && [[[UIDevice currentDevice] systemVersion] floatValue] < 11.2f) {
            //修正iOS11 多次暂停继续 文件大小不对的问题
            resumeData = [DownloadResumeData cleanResumeData:resumeData];
        }
        // 下载失败，将resumeData保存以便恢复下载
        [self saveResumeData:resumeData resumePath:downloadItem.resumeDataPath];
        /// -999是用户取消
        if (error.code != -999){
            downloadItem.downloadStatus = DownloadStateFailed;
        }
    } else {
        downloadItem.downloadStatus = DownloadStateFinished;
    }

    if (task.completionHander) {
        task.completionHander(error);
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if (self.completionHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionHandler();
            self.completionHandler = nil;
        });
    }
}

#pragma mark getter && setter

- (NSString *)identifier {
    return kDownloadBackgroundSessionIdentifier;
}

@end
