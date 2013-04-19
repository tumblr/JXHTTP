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
#if OS_OBJECT_USE_OBJC
@property (strong) dispatch_queue_t observationQueue;
@property (strong) dispatch_queue_t progressQueue;
@property (strong) dispatch_queue_t blockQueue;
#else
@property (assign) dispatch_queue_t observationQueue;
@property (assign) dispatch_queue_t progressQueue;
@property (assign) dispatch_queue_t blockQueue;
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
    dispatch_release(_blockQueue);
    _observationQueue = NULL;
    _progressQueue = NULL;
    _blockQueue = NULL;
    #endif
}

- (instancetype)init
{
    if (self = [super init]) {
        self.maxConcurrentOperationCount = JXHTTPOperationQueueDefaultMaxOps;
        self.uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
        self.observedOperationSet = [[NSMutableSet alloc] init];
        self.performsBlocksOnMainQueue = NO;
        self.delegate = nil;
        self.startDate = nil;
        self.finishDate = nil;

        self.willStartBlock = nil;
        self.willFinishBlock = nil;
        self.didStartBlock = nil;
        self.didUploadBlock = nil;
        self.didDownloadBlock = nil;
        self.didMakeProgressBlock = nil;
        self.didFinishBlock = nil;

        NSString *prefix = [[NSString alloc] initWithFormat:@"%@.%p.", NSStringFromClass([self class]), self];
        self.observationQueue = dispatch_queue_create([[prefix stringByAppendingString:@"observation"] UTF8String], DISPATCH_QUEUE_SERIAL);
        self.progressQueue = dispatch_queue_create([[prefix stringByAppendingString:@"progress"] UTF8String], DISPATCH_QUEUE_CONCURRENT);
        self.blockQueue = dispatch_queue_create([[prefix stringByAppendingString:@"blocks"] UTF8String], DISPATCH_QUEUE_SERIAL);

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
    if ([self.delegate respondsToSelector:selector])
        [self.delegate performSelector:selector onThread:[NSThread currentThread] withObject:self waitUntilDone:YES];

    JXHTTPQueueBlock block = [self blockForSelector:selector];

    if (!block)
        return;
    
    __weak JXHTTPOperationQueue *weakSelf = self;

    dispatch_async(self.performsBlocksOnMainQueue ? dispatch_get_main_queue() : self.blockQueue, ^{
        JXHTTPOperationQueue *strongSelf = weakSelf;
        if (strongSelf)
            block(strongSelf);
    });
}

- (JXHTTPQueueBlock)blockForSelector:(SEL)selector
{
    if (selector == @selector(httpOperationQueueWillStart:))
        return self.willStartBlock;
    if (selector == @selector(httpOperationQueueWillFinish:))
        return self.willFinishBlock;
    if (selector == @selector(httpOperationQueueDidStart:))
        return self.didStartBlock;
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
        
        BOOL starting = oldCount < 1 && newCount > 0;
        BOOL finishing = oldCount > 0 && newCount < 1;

        if (starting) {
            __weak JXHTTPOperationQueue *weakSelf = self;
            
            dispatch_barrier_async(self.progressQueue, ^{
                JXHTTPOperationQueue *strongSelf = weakSelf;
                if (!strongSelf)
                    return;
                
                strongSelf.bytesDownloadedPerOperation = [[NSMutableDictionary alloc] init];
                strongSelf.bytesUploadedPerOperation = [[NSMutableDictionary alloc] init];
                strongSelf.expectedDownloadBytesPerOperation = [[NSMutableDictionary alloc] init];
                strongSelf.expectedUploadBytesPerOperation = [[NSMutableDictionary alloc] init];
                strongSelf.downloadProgress = @0.0f;
                strongSelf.uploadProgress = @0.0f;
                strongSelf.bytesDownloaded = @0LL;
                strongSelf.bytesUploaded = @0LL;
                strongSelf.expectedDownloadBytes = @0LL;
                strongSelf.expectedUploadBytes = @0LL;
                strongSelf.finishDate = nil;
                strongSelf.startDate = now;
                [strongSelf performDelegateMethod:@selector(httpOperationQueueWillStart:)];
            });
        } else if (finishing) {
            __weak JXHTTPOperationQueue *weakSelf = self;

            dispatch_barrier_async(self.progressQueue, ^{
                JXHTTPOperationQueue *strongSelf = weakSelf;
                [strongSelf performDelegateMethod:@selector(httpOperationQueueWillFinish:)];
            });
        }

        for (JXHTTPOperation *operation in insertedArray) {
            if (![operation isKindOfClass:[JXHTTPOperation class]])
                continue;

            NSNumber *expectedUp = @(operation.requestBody.httpContentLength);
            NSString *uniqueString = [operation.uniqueString copy];

            __weak JXHTTPOperationQueue *weakSelf = self;
            
            dispatch_barrier_async(self.progressQueue, ^{
                JXHTTPOperationQueue *strongSelf = weakSelf;
                [strongSelf.expectedUploadBytesPerOperation setObject:expectedUp forKey:uniqueString];
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

            if ([operation isCancelled]) {
                NSString *uniqueString = [operation.uniqueString copy];

                __weak JXHTTPOperationQueue *weakSelf = self;
                
                dispatch_barrier_async(self.progressQueue, ^{
                    JXHTTPOperationQueue *strongSelf = weakSelf;
                    if (!strongSelf)
                        return;
                    
                    [strongSelf.bytesDownloadedPerOperation removeObjectForKey:uniqueString];
                    [strongSelf.bytesUploadedPerOperation removeObjectForKey:uniqueString];
                });
            }
            
            dispatch_sync(self.observationQueue, ^{
                if ([self.observedOperationSet containsObject:operation]) {
                    [operation removeObserver:self forKeyPath:@"bytesDownloaded" context:JXHTTPOperationQueueContext];
                    [operation removeObserver:self forKeyPath:@"bytesUploaded" context:JXHTTPOperationQueueContext];
                    [operation removeObserver:self forKeyPath:@"response" context:JXHTTPOperationQueueContext];
                    
                    [self.observedOperationSet removeObject:operation];
                }
            });
        }

        if (starting) {
            __weak JXHTTPOperationQueue *weakSelf = self;
            
            dispatch_barrier_async(self.progressQueue, ^{
                JXHTTPOperationQueue *strongSelf = weakSelf;
                [strongSelf performDelegateMethod:@selector(httpOperationQueueDidStart:)];
            });
        } else if (finishing) {
            __weak JXHTTPOperationQueue *weakSelf = self;
            
            dispatch_barrier_async(self.progressQueue, ^{
                JXHTTPOperationQueue *strongSelf = weakSelf;
                if (!strongSelf)
                    return;

                strongSelf.finishDate = now;
                [strongSelf performDelegateMethod:@selector(httpOperationQueueDidFinish:)];
            });
        }

        return;
    }

    if ([keyPath isEqualToString:@"response"]) {
        JXHTTPOperation *operation = object;
        long long expectedDown = [operation.response expectedContentLength];
        NSString *uniqueString = [operation.uniqueString copy];

        if (expectedDown && expectedDown != NSURLResponseUnknownLength) {
            __weak JXHTTPOperationQueue *weakSelf = self;

            dispatch_barrier_async(self.progressQueue, ^{
                JXHTTPOperationQueue *strongSelf = weakSelf;
                [strongSelf.expectedDownloadBytesPerOperation setObject:@(expectedDown) forKey:uniqueString];
            });
        }

        return;
    }

    if ([keyPath isEqualToString:@"bytesDownloaded"]) {
        JXHTTPOperation *operation = (JXHTTPOperation *)object;
        long long downloaded = operation.bytesDownloaded;
        NSString *uniqueString = [operation.uniqueString copy];

        __weak JXHTTPOperationQueue *weakSelf = self;

        dispatch_barrier_async(self.progressQueue, ^{
            JXHTTPOperationQueue *strongSelf = weakSelf;
            if (!strongSelf)
                return;
            
            [strongSelf.bytesDownloadedPerOperation setObject:@(downloaded) forKey:uniqueString];
            
            long long bytesDownloaded = 0LL;
            long long expectedDownloadBytes = 0LL;
            
            for (NSString *opString in [strongSelf.bytesDownloadedPerOperation allKeys]) {
                bytesDownloaded += [[strongSelf.bytesDownloadedPerOperation objectForKey:opString] longLongValue];
            }
            
            for (NSString *opString in [strongSelf.expectedDownloadBytesPerOperation allKeys]) {
                expectedDownloadBytes += [[strongSelf.expectedDownloadBytesPerOperation objectForKey:opString] longLongValue];
            }
            
            strongSelf.bytesDownloaded = @(bytesDownloaded);
            strongSelf.expectedDownloadBytes = @(expectedDownloadBytes);
            strongSelf.downloadProgress = expectedDownloadBytes ? @(bytesDownloaded / (float)expectedDownloadBytes) : @0.0f;
            [strongSelf performDelegateMethod:@selector(httpOperationQueueDidUpload:)];
            [strongSelf performDelegateMethod:@selector(httpOperationQueueDidMakeProgress:)];
        });

        return;
    }

    if ([keyPath isEqualToString:@"bytesUploaded"]) {
        JXHTTPOperation *operation = (JXHTTPOperation *)object;

        long long uploaded = operation.bytesUploaded;
        NSString *uniqueString = [operation.uniqueString copy];

        __weak JXHTTPOperationQueue *weakSelf = self;

        dispatch_barrier_async(self.progressQueue, ^{
            JXHTTPOperationQueue *strongSelf = weakSelf;
            if (!strongSelf)
                return;
            
            [strongSelf.bytesUploadedPerOperation setObject:@(uploaded) forKey:uniqueString];
            
            long long bytesUploaded = 0LL;
            long long expectedUploadBytes = 0LL;

            for (NSString *opString in [strongSelf.bytesUploadedPerOperation allKeys]) {
                bytesUploaded += [[strongSelf.bytesUploadedPerOperation objectForKey:opString] longLongValue];
            }

            for (NSString *opString in [strongSelf.expectedUploadBytesPerOperation allKeys]) {
                expectedUploadBytes += [[strongSelf.expectedUploadBytesPerOperation objectForKey:opString] longLongValue];
            }

            strongSelf.bytesUploaded = @(bytesUploaded);
            strongSelf.expectedUploadBytes = @(expectedUploadBytes);
            strongSelf.uploadProgress = expectedUploadBytes ? @(bytesUploaded / (float)expectedUploadBytes) : @0.0f;
            [strongSelf performDelegateMethod:@selector(httpOperationQueueDidDownload:)];
            [strongSelf performDelegateMethod:@selector(httpOperationQueueDidMakeProgress:)];
        });

        return;
    }
}

@end
