//
//  YYDownloadSessionManager.m
//  YYDownloadManager
//
//  Created by Jonathan on 2023/3/3.
//

#import "YYDownloadSessionManager.h"
#import "YYDownloadTaskManager.h"
#import "YYDownloadManager.h"
#import "YYDownloadHelper.h"
#import "YYDownloadResumeData.h"

// 后台下载任务标识
static NSString *const kDownloadBackgroundSessionIdentifier = @"com.jonathan.download.backgroundidentifier";

@interface YYDownloadSessionManager ()<NSURLSessionDownloadDelegate>
/// 任务会话
@property (nonatomic, strong) NSURLSession *sessionManager;
/// 锁
@property (nonatomic, strong) NSLock *lock;
/// 下载中任务
@property (nonatomic, strong) NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *runningTask;
/// 等待下载任务
@property (nonatomic, strong) NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *waitingTask;

@end

@implementation YYDownloadSessionManager

+ (nonnull instancetype)sharedManager{
    static dispatch_once_t once;
    static YYDownloadSessionManager *instance;
    dispatch_once(&once, ^{
        instance = [YYDownloadSessionManager new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self runningTask];
        [self waitingTask];
        [self restoreStatus];
    }
    return self;
}

- (void)restoreStatus {
    [self.sessionManager getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            NSLog(@"~~~~~~~~~~~~%zd",downloadTask.state);
            NSString *downloadURL = downloadTask.currentRequest.URL.absoluteString;
            NSObject<YYDownloadTaskDelegate> *task = [[YYDownloadTaskManager shareManager] taskWithDownloadURL:downloadURL];
            if (!task) {
                [downloadTask cancel];
                continue;
            }
            if (task.downloadStatus == YYDownloadStatusFinished) {
                [downloadTask cancel];
                continue;
            }
            
            if (downloadTask.state == NSURLSessionTaskStateRunning) {
                task.downloadTask = downloadTask;
                task.downloadStatus = YYDownloadStatusDownloading;
            }
        }
    }];
}

- (NSURLSessionDownloadTask *)prepareDownloadTask:(NSObject<YYDownloadTaskDelegate> *)task {
    NSURL *URL = [NSURL URLWithString:task.downloadURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setAllHTTPHeaderFields:task.requestHeader];
    NSData *resumeData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:task.resumeDataPath]];
    NSURLSessionDownloadTask *downloadTask;
    if (resumeData) {
        downloadTask = [YYDownloadResumeData downloadTaskWithCorrectResumeData:resumeData urlSession:self.sessionManager];
    }
    else {
        downloadTask = [self.sessionManager downloadTaskWithRequest:request];
    }
    return downloadTask;
}

- (void)startNextTask {
    if (self.runningTask.count > [YYDownloadManager shareManager].configuration.maxTaskCount) return;
    if (!self.waitingTask.count) return;
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"queuePriority" ascending:NO];
    [self.waitingTask sortUsingDescriptors:@[sortDescriptor]];
    NSObject<YYDownloadTaskDelegate> *next = self.waitingTask.firstObject;
//    if (YES) {
//        next.downloadStatus = YYDownloadStatusPaused;
//        return;
//    }
    NSURLSessionDownloadTask *downloadTask = [self prepareDownloadTask:next];
    if (!downloadTask) return;
    [self appendTaskToRuningQueueAndRemoveFromWaitQueue:next];
    next.downloadStatus = YYDownloadStatusDownloading;
    next.downloadTask = downloadTask;
    [next.downloadTask resume];
}

- (void)pauseTask:(NSObject<YYDownloadTaskDelegate> *)task startNext:(BOOL)startNext {
    [self removeTaskFromQueue:task];
    task.downloadStatus = YYDownloadStatusPaused;
    if (task.downloadTask) {
        [task.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {}];
        task.downloadTask = nil;
    }
    if (startNext) {
        [self startNextTask];
    }
}

- (void)removeTask:(NSObject<YYDownloadTaskDelegate> *)task startNext:(BOOL)startNext {
    if (task.downloadTask) {
        [task.downloadTask cancel];
    }
    [[YYDownloadTaskManager shareManager] removeTask:task];
    [self removeTaskFromQueue:task];
    if (startNext) {
        [self startNextTask];
    }
}

- (void)saveResumeData:(NSData *)resumeData resumePath:(NSString *)resumePath {
    if (!resumeData) return;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0f && [[[UIDevice currentDevice] systemVersion] floatValue] < 11.2f) {
        //修正iOS11 多次暂停继续 文件大小不对的问题
        resumeData = [YYDownloadResumeData cleanResumeData:resumeData];
    }
    // 下载失败，将resumeData保存以便恢复下载
    [YYDownloadHelper writeToPath:resumePath data:resumeData];
}

- (void)appendTaskToWaitQueueAndRemoveFormRuningQueue:(NSObject<YYDownloadTaskDelegate> *)task {
    [self.lock lock];
    [self.waitingTask addObject:task];
    [self.runningTask removeObject:task];
    [self.lock unlock];
}

- (void)appendTaskToRuningQueueAndRemoveFromWaitQueue:(NSObject<YYDownloadTaskDelegate> *)task {
    [self.lock lock];
    [self.waitingTask removeObject:task];
    [self.runningTask addObject:task];
    [self.lock unlock];
}


- (void)removeTaskFromQueue:(NSObject<YYDownloadTaskDelegate> *)task {
    [self.lock lock];
    [self.waitingTask removeObject:task];
    [self.runningTask removeObject:task];
    [self.lock unlock];
}

#pragma mark public method

- (void)addTask:(NSObject<YYDownloadTaskDelegate> *)task {
    if (!task) return;
    if ([[YYDownloadTaskManager shareManager] taskWithDownloadURL:task.downloadURL]) {
        NSLog(@"YYDownload:已在任务列表");
        return;
    }
    [[YYDownloadTaskManager shareManager] addTask:task];
    task.downloadStatus = YYDownloadStatusWaiting;
    [self appendTaskToWaitQueueAndRemoveFormRuningQueue:task];
    [self startNextTask];
}

- (void)pauseTask:(NSObject<YYDownloadTaskDelegate> *)task {
    if (!task) return;
    if (![[YYDownloadTaskManager shareManager] taskWithDownloadURL:task.downloadURL]) return;
    [self pauseTask:task startNext:YES];
}

- (void)pauseAllTask {
    for (NSObject<YYDownloadTaskDelegate> *task in [YYDownloadTaskManager shareManager].downloadingTasks) {
        [self pauseTask:task startNext:NO];
    }
}

- (void)removeTask:(NSObject<YYDownloadTaskDelegate> *)task {
    if (!task) return;
    if (![[YYDownloadTaskManager shareManager] taskWithDownloadURL:task.downloadURL]) return;
    [[YYDownloadTaskManager shareManager] removeTask:task];
    [self removeTask:task startNext:YES];
}

- (void)removeAllTask {
    for (NSObject<YYDownloadTaskDelegate> *task in [YYDownloadTaskManager shareManager].downloadingTasks) {
        [self removeTask:task startNext:NO];
    }
}

- (void)resumeTask:(NSObject<YYDownloadTaskDelegate> *)task {
    if(!task) return;
    if (![[YYDownloadTaskManager shareManager] taskWithDownloadURL:task.downloadURL]) return;
    if (task.downloadStatus == YYDownloadStatusPaused || task.downloadStatus == YYDownloadStatusWaiting || task.downloadStatus == YYDownloadStatusUnknow) {
        [self appendTaskToWaitQueueAndRemoveFormRuningQueue:task];
        [self startNextTask];
    }
}

- (void)resumeAllTask {
    for (NSObject<YYDownloadTaskDelegate> *task in [YYDownloadTaskManager shareManager].downloadingTasks) {
        [self resumeTask:task];
    }
}


#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    NSObject<YYDownloadTaskDelegate> *task = [[YYDownloadTaskManager shareManager] taskWithDownloadURL:downloadTask.currentRequest.URL.absoluteString];
    if (!task) return;
    int64_t expectedContentLength = downloadTask.response.expectedContentLength;
    task.downloadedSize = totalBytesWritten;
    task.totalSize = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite:expectedContentLength;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadProgressUpdateNotification object:task];
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSObject<YYDownloadTaskDelegate> *task = [[YYDownloadTaskManager shareManager] taskWithDownloadURL:downloadTask.currentRequest.URL.absoluteString];
    if (!task) return;
    NSError *error;
    if ([YYDownloadHelper moveItemAtURL:location toURL:[NSURL fileURLWithPath:task.filePath]]) {
        [YYDownloadHelper removeItemAtPath:task.resumeDataPath];
        NSLog(@"下载完成:downloadURL:%@\n path:%@",task.downloadURL,task.filePath);
    }
    else {
        NSLog(@"%@",error.description);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDownloadTask *)downloadTask didCompleteWithError:(NSError *)error {
    NSObject<YYDownloadTaskDelegate> *task = [[YYDownloadTaskManager shareManager] taskWithDownloadURL:downloadTask.currentRequest.URL.absoluteString];
    if (!task) return;
    [self removeTaskFromQueue:task];
    if (error) {
        NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        [self saveResumeData:resumeData resumePath:task.resumeDataPath];
        /// -999是用户取消
        if (error.code != -999){
            task.downloadStatus = YYDownloadStatusFailed;
        }
        else {
            task.downloadStatus = YYDownloadStatusPaused;
        }
    } else {
        task.downloadStatus = YYDownloadStatusFinished;
    }

    if (task.completionHander) {
        task.completionHander();
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

- (NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *)runningTask {
    if (!_runningTask) {
        _runningTask = [[[YYDownloadTaskManager shareManager] TaskForStatus:YYDownloadStatusDownloading] mutableCopy];
    }
    return _runningTask;
}

- (NSMutableArray<NSObject<YYDownloadTaskDelegate> *> *)waitingTask {
    if (!_waitingTask) {
        _waitingTask = [[[YYDownloadTaskManager shareManager] TaskForStatus:YYDownloadStatusWaiting] mutableCopy];
    }
    return _waitingTask;
}

- (NSURLSession *)sessionManager {
    if (!_sessionManager) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kDownloadBackgroundSessionIdentifier];
        configuration.allowsCellularAccess = [YYDownloadManager shareManager].configuration.allowsCellularAccess;
        configuration.timeoutIntervalForRequest = [YYDownloadManager shareManager].configuration.timeoutIntervalForRequest;
        configuration.HTTPMaximumConnectionsPerHost = [YYDownloadManager shareManager].configuration.maxTaskCount;
        configuration.sessionSendsLaunchEvents = YES;
        _sessionManager = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _sessionManager;
}

- (NSLock *)lock {
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
}

- (NSString *)identifier {
    return kDownloadBackgroundSessionIdentifier;
}


@end
