//
//  DownloadSessionManager.m
//  DownloadManager
//
//  Created by Apple on 2023/3/3.
//

#import "DownloadSessionManager.h"
#import "DownloadHelper.h"

// 后台下载任务标识
static NSString *const kDownloadBackgroundSessionIdentifier = @"com.jonathan.download.backgroundidentifier";

@interface DownloadSessionManager ()<NSURLSessionDataDelegate>
/// 任务会话
@property (nonatomic, strong) NSURLSession *sessionManager;
/// 所有任务回调信息map
@property (nonatomic, strong) NSMutableDictionary<NSURLSessionDataTask *,DownloadSessionDataTask *> *allTaskMap;
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
}

#pragma mark public method

- (void)cancelAllTask{
    [self.sessionManager invalidateAndCancel];
}

- (DownloadSessionDataTask *)downloadTaskWithDownloadItem:(DownloadModel *)item {
    DownloadSessionDataTask *task = [[DownloadSessionDataTask alloc] initWithDownloadItem:item];
    NSURL *URL = [NSURL URLWithString:item.fileURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.timeoutInterval = 30;
    int64_t downloadedSize = 0;
    if ([[NSFileManager defaultManager] fileExistsAtPath:item.savePath]) {
        downloadedSize = [[NSFileManager defaultManager] attributesOfItemAtPath:item.savePath error:nil].fileSize;
    }
    NSString *range = [NSString stringWithFormat:@"bytes=%lld-",downloadedSize];
    [request setAllHTTPHeaderFields:item.httpHeaders];
    [request setValue:range forHTTPHeaderField:@"Range"];
    task.dataTask = [self.sessionManager dataTaskWithRequest:request];
    [self.lock lock];
    [self.allTaskMap setObject:task forKey:task.dataTask];
    [self.lock unlock];
    [task.dataTask resume];
    return task;
}

- (void)cancelTask:(DownloadSessionDataTask *)task {
    if (!task) return;
    [task.dataTask cancel];
    [self.lock lock];
    [self.allTaskMap removeObjectForKey:task.dataTask];
    [self.lock unlock];
}

#pragma mark  NSURLSessionDataDelegate

// 接收到服务器响应的时候调用
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    DownloadSessionDataTask *downloadTask = [self.allTaskMap objectForKey:dataTask];
    if (!downloadTask) return;
    DownloadModel *downloadItem = downloadTask.downloadItem;
    if (!downloadItem) return;
    if (downloadItem.downloadedSize == 0) {
        downloadItem.totalSize = response.expectedContentLength;
    }
    [downloadTask.stream open];
    completionHandler(NSURLSessionResponseAllow);
}

// 接收到服务器返回数据时调用，会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    DownloadSessionDataTask *downloadTask = [self.allTaskMap objectForKey:dataTask];
    if (!downloadTask) return;
    DownloadModel *downloadItem = downloadTask.downloadItem;
    if (!downloadItem) return;
    downloadItem.downloadedSize += data.length;
    NSLog(@"~~~~~~~~~~%lld",downloadItem.downloadedSize);
    NSLog(@"~~~~~~~~~~%lld",downloadItem.totalSize);
    // 输出流写数据
    [downloadTask.stream write:data.bytes maxLength:data.length];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadProgressUpdateNotification object:downloadItem];
    });
}

// 当请求完成之后调用，如果请求失败error有值
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    DownloadSessionDataTask *downloadTask = [self.allTaskMap objectForKey:(NSURLSessionDataTask *)task];
    if (!downloadTask) return;
    DownloadModel *downloadItem = downloadTask.downloadItem;
    if (!downloadItem) return;
    // 关闭stream
    [downloadTask.stream close];
    downloadTask.stream = nil;
    if (downloadTask.completionHander) {
        downloadTask.completionHander(error);
    }
}

@end
