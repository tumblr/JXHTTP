#import "JXHTTPOperationQueue.h"
#import "JXHTTPOperation.h"

static void * JXHTTPOperationQueueContext = &JXHTTPOperationQueueContext;
static NSInteger JXHTTPOperationQueueDefaultMaxOps = 4;

@interface JXHTTPOperationQueue ()
@property (strong) NSMutableDictionary *bytesDownloadedPerOperation;
@property (strong) NSMutableDictionary *bytesUploadedPerOperation;
@property (strong) NSMutableDictionary *expectedDownloadBytesPerOperation;
@property (strong) NSMutableDictionary *expectedUploadBytesPerOperation;
@property (strong) NSDate *startDate;
@property (strong) NSDate *finishDate;
@property (strong) NSString *uniqueString;
@property (strong) NSNumber *downloadProgress;
@property (strong) NSNumber *uploadProgress;
@property (strong) NSNumber *bytesDownloaded;
@property (strong) NSNumber *bytesUploaded;
@property (strong) NSNumber *expectedDownloadBytes;
@property (strong) NSNumber *expectedUploadBytes;
@property (strong) NSMutableSet *observedOperationSet;
@property (strong) NSOperationQueue *blockQueue;
#if OS_OBJECT_USE_OBJC
@property (strong) dispatch_queue_t observationQueue;
@property (strong) dispatch_queue_t progressQueue;
#else
@property (assign) dispatch_queue_t observationQueue;
@property (assign) dispatch_queue_t progressQueue;
#endif
@end

@implementation JXHTTPOperationQueue

#pragma mark - Initialization

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"operations" context:JXHTTPOperationQueueContext];

    #if !OS_OBJECT_USE_OBJC
    dispatch_release(_observationQueue);
    dispatch_release(_progressQueue);
    #endif
}

- (instancetype)init
{
    if (self = [super init]) {
        self.maxConcurrentOperationCount = JXHTTPOperationQueueDefaultMaxOps;
        self.uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
        self.observedOperationSet = [[NSMutableSet alloc] init];
        self.performsDelegateMethodsOnMainThread = NO;
        self.performsBlocksOnMainThread = NO;
        self.delegate = nil;
        self.startDate = nil;
        self.finishDate = nil;

        self.blockQueue = [[NSOperationQueue alloc] init];
        self.blockQueue.maxConcurrentOperationCount = 1;

        NSString * const nameFormat = [[NSString alloc] initWithFormat:@"%@.%%@.%p", NSStringFromClass([self class]), self];
        self.observationQueue = dispatch_queue_create([[[NSString alloc] initWithFormat:nameFormat, @"observation"] UTF8String], DISPATCH_QUEUE_SERIAL);
        self.progressQueue = dispatch_queue_create([[[NSString alloc] initWithFormat:nameFormat, @"progress"] UTF8String], DISPATCH_QUEUE_CONCURRENT);

        [self addObserver:self
               forKeyPath:@"operations"
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:JXHTTPOperationQueueContext];
    }
    return self;
}

+ (instancetype)sharedQueue
{
    static id sharedQueue = nil;
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
        sharedQueue = [[self alloc] init];
    });

    return sharedQueue;
}

+ (instancetype)queue
{
    return [[self alloc] init];
}

#pragma mark - Accessors

- (NSTimeInterval)elapsedSeconds
{
    if (self.startDate) {
        NSDate *endDate = self.finishDate ? self.finishDate : [[NSDate alloc] init];
        return [endDate timeIntervalSinceDate:self.startDate];
    } else {
        return 0.0;
    }
}

#pragma mark - Private Methods

- (void)performDelegateMethod:(SEL)selector
{
    JXHTTPQueueBlock block = [self blockForSelector:selector];
    
    if (!self.delegate && !block)
        return;
    
    if (self.performsDelegateMethodsOnMainThread) {
        if ([self.delegate respondsToSelector:selector])
            [self.delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
    } else {
        if ([self.delegate respondsToSelector:selector])
            [self.delegate performSelector:selector onThread:[NSThread currentThread] withObject:self waitUntilDone:YES];
    }

    if (!block)
        return;

    [(self.performsBlocksOnMainThread ? [NSOperationQueue mainQueue] : self.blockQueue) addOperationWithBlock:^{
        block(self);
    }];
}

- (JXHTTPQueueBlock)blockForSelector:(SEL)selector
{
    if (selector == @selector(httpOperationQueueWillStart:))
        return self.willStartBlock;
    if (selector == @selector(httpOperationQueueDidUpload:))
        return self.didUploadBlock;
    if (selector == @selector(httpOperationQueueDidDownload:))
        return self.didDownloadBlock;
    if (selector == @selector(httpOperationQueueDidMakeProgress:))
        return self.didMakeProgressBlock;
    if (selector == @selector(httpOperationQueueDidFinish:))
        return self.didFinishBlock;
    return nil;
}

#pragma mark - <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != JXHTTPOperationQueueContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    __weak __typeof(self) weakSelf = self;

    if (object == self && [keyPath isEqualToString:@"operations"]) {
        if (![[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeSetting)
            return;
        
        NSDate *now = [[NSDate alloc] init];

        NSArray *newOperationsArray = [change objectForKey:NSKeyValueChangeNewKey];
        NSArray *oldOperationsArray = [change objectForKey:NSKeyValueChangeOldKey];
        
        NSMutableArray *insertedArray = [[NSMutableArray alloc] initWithArray:newOperationsArray];
        NSMutableArray *removedArray = [[NSMutableArray alloc] initWithArray:oldOperationsArray];
        
        [insertedArray removeObjectsInArray:oldOperationsArray];
        [removedArray removeObjectsInArray:newOperationsArray];

        NSUInteger newCount = [newOperationsArray count];
        NSUInteger oldCount = [oldOperationsArray count];

        if (oldCount < 1 && newCount > 0) {
            dispatch_barrier_async(self.progressQueue, ^{
                weakSelf.finishDate = nil;
                weakSelf.startDate = [[NSDate alloc] init];
                weakSelf.bytesDownloadedPerOperation = [[NSMutableDictionary alloc] init];
                weakSelf.bytesUploadedPerOperation = [[NSMutableDictionary alloc] init];
                weakSelf.expectedDownloadBytesPerOperation = [[NSMutableDictionary alloc] init];
                weakSelf.expectedUploadBytesPerOperation = [[NSMutableDictionary alloc] init];
                weakSelf.downloadProgress = @0.0f;
                weakSelf.uploadProgress = @0.0f;
                weakSelf.bytesDownloaded = @0LL;
                weakSelf.bytesUploaded = @0LL;
                weakSelf.expectedDownloadBytes = @0LL;
                weakSelf.expectedUploadBytes = @0LL;

                [weakSelf performDelegateMethod:@selector(httpOperationQueueWillStart:)];
            });
        }

        for (JXHTTPOperation *operation in insertedArray) {
            if (![operation isKindOfClass:[JXHTTPOperation class]])
                continue;

            NSNumber *expectedUp = @(operation.requestBody.httpContentLength);
            NSString *uniqueString = [operation.uniqueString copy];

            dispatch_barrier_async(self.progressQueue, ^{
                [weakSelf.expectedUploadBytesPerOperation setObject:expectedUp forKey:uniqueString];
            });
            
            dispatch_sync(self.observationQueue, ^{
                if (![self.observedOperationSet containsObject:operation]) {
                    [operation addObserver:self forKeyPath:@"bytesDownloaded" options:0 context:JXHTTPOperationQueueContext];
                    [operation addObserver:self forKeyPath:@"bytesUploaded" options:0 context:JXHTTPOperationQueueContext];
                    [operation addObserver:self forKeyPath:@"response" options:0 context:JXHTTPOperationQueueContext];

                    [self.observedOperationSet addObject:operation];
                }
            });
        }

        for (JXHTTPOperation *operation in removedArray) {
            if (![operation isKindOfClass:[JXHTTPOperation class]])
                continue;
            
            dispatch_sync(self.observationQueue, ^{
                if ([self.observedOperationSet containsObject:operation]) {
                    [operation removeObserver:self forKeyPath:@"bytesDownloaded" context:JXHTTPOperationQueueContext];
                    [operation removeObserver:self forKeyPath:@"bytesUploaded" context:JXHTTPOperationQueueContext];
                    [operation removeObserver:self forKeyPath:@"response" context:JXHTTPOperationQueueContext];

                    [self.observedOperationSet removeObject:operation];
                }
            });

            if ([operation isCancelled]) {
                NSString *uniqueString = [operation.uniqueString copy];

                dispatch_barrier_async(self.progressQueue, ^{
                    [weakSelf.bytesDownloadedPerOperation removeObjectForKey:uniqueString];
                    [weakSelf.bytesUploadedPerOperation removeObjectForKey:uniqueString];
                });
            }
        }
        
        if (oldCount > 0 && newCount < 1) {
            dispatch_barrier_async(self.progressQueue, ^{
                weakSelf.finishDate = now;
                [weakSelf performDelegateMethod:@selector(httpOperationQueueDidFinish:)];
            });
        }

        return;
    }

    if ([keyPath isEqualToString:@"response"]) {
        JXHTTPOperation *operation = object;
        long long expectedDown = [operation.response expectedContentLength];
        NSString *uniqueString = [operation.uniqueString copy];

        if (expectedDown && expectedDown != NSURLResponseUnknownLength) {
            dispatch_barrier_async(self.progressQueue, ^{
                [weakSelf.expectedDownloadBytesPerOperation setObject:@(expectedDown) forKey:uniqueString];
            });
        }

        return;
    }

    if ([keyPath isEqualToString:@"bytesDownloaded"]) {
        JXHTTPOperation *operation = (JXHTTPOperation *)object;
        long long bytesDownloaded = operation.bytesDownloaded;
        NSString *uniqueString = [operation.uniqueString copy];

        dispatch_barrier_async(self.progressQueue, ^{
            [weakSelf.bytesDownloadedPerOperation setObject:@(bytesDownloaded) forKey:uniqueString];
        });

        dispatch_sync(self.progressQueue, ^{
            long long bytesDownloaded = 0LL;
            long long expectedDownloadBytes = 0LL;

            for (NSString *opString in [self.bytesDownloadedPerOperation allKeys]) {
                bytesDownloaded += [[self.bytesDownloadedPerOperation objectForKey:opString] longLongValue];
            }

            for (NSString *opString in [self.expectedDownloadBytesPerOperation allKeys]) {
                expectedDownloadBytes += [[self.expectedDownloadBytesPerOperation objectForKey:opString] longLongValue];
            }

            dispatch_barrier_async(self.progressQueue, ^{
                weakSelf.bytesDownloaded = @(bytesDownloaded);
                weakSelf.expectedDownloadBytes = @(expectedDownloadBytes);
                weakSelf.downloadProgress = expectedDownloadBytes ? @(bytesDownloaded / (float)expectedDownloadBytes) : @0.0f;
                [weakSelf performDelegateMethod:@selector(httpOperationQueueDidUpload:)];
                [weakSelf performDelegateMethod:@selector(httpOperationQueueDidMakeProgress:)];
            });
        });

        return;
    }

    if ([keyPath isEqualToString:@"bytesUploaded"]) {
        JXHTTPOperation *operation = (JXHTTPOperation *)object;

        long long bytesUploaded = operation.bytesUploaded;
        NSString *uniqueString = [operation.uniqueString copy];

        dispatch_barrier_async(self.progressQueue, ^{
            [weakSelf.bytesUploadedPerOperation setObject:@(bytesUploaded) forKey:uniqueString];
        });

        dispatch_sync(self.progressQueue, ^{
            long long bytesUploaded = 0LL;
            long long expectedUploadBytes = 0LL;

            for (NSString *opString in [self.bytesUploadedPerOperation allKeys]) {
                bytesUploaded += [[self.bytesUploadedPerOperation objectForKey:opString] longLongValue];
            }

            for (NSString *opString in [self.expectedUploadBytesPerOperation allKeys]) {
                expectedUploadBytes += [[self.expectedUploadBytesPerOperation objectForKey:opString] longLongValue];
            }

            dispatch_barrier_async(self.progressQueue, ^{
                weakSelf.bytesUploaded = @(bytesUploaded);
                weakSelf.expectedUploadBytes = @(expectedUploadBytes);
                weakSelf.uploadProgress = expectedUploadBytes ? @(bytesUploaded / (float)expectedUploadBytes) : @0.0f;
                [weakSelf performDelegateMethod:@selector(httpOperationQueueDidDownload:)];
                [weakSelf performDelegateMethod:@selector(httpOperationQueueDidMakeProgress:)];
            });
        });

        return;
    }
}

@end
