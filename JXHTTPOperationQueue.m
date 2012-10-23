#import "JXHTTPOperationQueue.h"
#import "JXHTTPOperation.h"

static void * JXHTTPOperationQueueContext = &JXHTTPOperationQueueContext;
static NSInteger JXHTTPOperationQueueDefaultMaxOps = 4;

@interface JXHTTPOperationQueue ()
@property (retain) NSMutableDictionary *bytesReceivedPerOperation;
@property (retain) NSMutableDictionary *bytesSentPerOperation;
@property (retain) NSMutableDictionary *expectedDownloadBytesPerOperation;
@property (retain) NSMutableDictionary *expectedUploadBytesPerOperation;
@property (retain) NSDate *startDate;
@property (retain) NSDate *finishDate;
@property (retain) NSString *uniqueString;
@property (retain) NSNumber *downloadProgress;
@property (retain) NSNumber *uploadProgress;
@property (retain) NSNumber *bytesDownloaded;
@property (retain) NSNumber *bytesUploaded;
@property (retain) NSNumber *expectedUploadBytes;
@property (retain) NSNumber *expectedDownloadBytes;
@property (retain) NSMutableSet *observedOperationSet;
@property (assign) dispatch_queue_t observationQueue;
@property (assign) dispatch_queue_t progressMathQueue;
@property (retain) NSOperationQueue *blockQueue;
@end

@implementation JXHTTPOperationQueue

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"operations" context:JXHTTPOperationQueueContext];

    self.delegate = nil;

    [_bytesReceivedPerOperation release];
    [_bytesSentPerOperation release];
    [_expectedUploadBytesPerOperation release];
    [_expectedDownloadBytesPerOperation release];
    [_expectedDownloadBytes release];
    [_expectedUploadBytes release];
    [_bytesDownloaded release];
    [_bytesUploaded release];
    [_downloadProgress release];
    [_uploadProgress release];
    [_uniqueString release];
    [_observedOperationSet release];
    [_startDate release];
    [_finishDate release];

    [_willStartBlock release];
    [_didUploadBlock release];
    [_didDownloadBlock release];
    [_didMakeProgressBlock release];
    [_didFinishBlock release];
    [_blockQueue release];

    dispatch_release(_observationQueue);
    dispatch_release(_progressMathQueue);

    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.maxConcurrentOperationCount = JXHTTPOperationQueueDefaultMaxOps;
        self.uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
        self.observedOperationSet = [NSMutableSet set];

        self.startDate = nil;
        self.finishDate = nil;

        self.blockQueue = [[[NSOperationQueue alloc] init] autorelease];
        self.blockQueue.maxConcurrentOperationCount = 1;

        self.observationQueue = dispatch_queue_create("JXHTTPOperationQueue.observation", DISPATCH_QUEUE_SERIAL);
        self.progressMathQueue = dispatch_queue_create("JXHTTPOperationQueue.progressMath", DISPATCH_QUEUE_CONCURRENT);

        [self addObserver:self forKeyPath:@"operations" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:JXHTTPOperationQueueContext];
    }
    return self;
}

+ (id)sharedQueue
{
    static id sharedQueue;
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
        sharedQueue = [[self alloc] init];
    });

    return sharedQueue;
}

#pragma mark -
#pragma mark Accessors

- (NSTimeInterval)elapsedSeconds
{
    if (self.startDate) {
        NSDate *endDate = self.finishDate ? self.finishDate : [NSDate date];
        return [endDate timeIntervalSinceDate:self.startDate];
    }
    return 0.0;
}

#pragma mark -
#pragma mark Private Methods

- (void)performDelegateMethod:(SEL)selector
{
    __block JXHTTPQueueBlock block = [self blockForSelector:selector];

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

    if (self.performsBlocksOnMainThread) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            block(self);
        }];
    } else {
        __block JXHTTPOperationQueue *blockSelf = [self retain];
        [self.blockQueue addOperationWithBlock:^{
            block(blockSelf);
            [blockSelf release];
        }];
    }
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

- (void)resetProgress
{
    __block JXHTTPOperationQueue *blockSelf = self;

    dispatch_barrier_async(self.progressMathQueue, ^{
        blockSelf.bytesReceivedPerOperation = [NSMutableDictionary dictionary];
        blockSelf.bytesSentPerOperation = [NSMutableDictionary dictionary];
        blockSelf.expectedDownloadBytesPerOperation = [NSMutableDictionary dictionary];
        blockSelf.expectedUploadBytesPerOperation = [NSMutableDictionary dictionary];
        blockSelf.downloadProgress = @0.0f;
        blockSelf.uploadProgress = @0.0f;
        blockSelf.bytesDownloaded = @0LL;
        blockSelf.bytesUploaded = @0LL;
        blockSelf.expectedDownloadBytes = @0LL;
        blockSelf.expectedUploadBytes = @0LL;
    });
}

#pragma mark -
#pragma mark <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != JXHTTPOperationQueueContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    __block JXHTTPOperationQueue *blockSelf = self;

    if (object == self && [keyPath isEqualToString:@"operations"]) {
        if (![[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeSetting)
            return;

        NSArray *newOperationsArray = [change objectForKey:NSKeyValueChangeNewKey];
        NSArray *oldOperationsArray = [change objectForKey:NSKeyValueChangeOldKey];
        NSMutableArray *insertedArray = [NSMutableArray arrayWithArray:newOperationsArray];
        NSMutableArray *removedArray = [NSMutableArray arrayWithArray:oldOperationsArray];
        [insertedArray removeObjectsInArray:oldOperationsArray];
        [removedArray removeObjectsInArray:newOperationsArray];

        NSUInteger newCount = [newOperationsArray count];
        NSUInteger oldCount = [oldOperationsArray count];
        NSDate *now = [NSDate date];

        if (oldCount < 1 && newCount > 0) {
            [self resetProgress];
            self.startDate = now;
            self.finishDate = nil;
            [self performDelegateMethod:@selector(httpOperationQueueWillStart:)];
        }

        for (JXHTTPOperation *operation in insertedArray) {
            if (![operation isKindOfClass:[JXHTTPOperation class]])
                continue;

            NSNumber *expectedUp = @(operation.requestBody.httpContentLength);
            NSString *uniqueString = [NSString stringWithString:operation.uniqueString];

            dispatch_barrier_async(self.progressMathQueue, ^{
                [blockSelf.expectedUploadBytesPerOperation setObject:expectedUp forKey:uniqueString];
            });
            
            dispatch_sync(self.observationQueue, ^{
                BOOL observed = [self.observedOperationSet containsObject:operation];

                if (!observed) {
                    [operation addObserver:self forKeyPath:@"bytesReceived" options:0 context:JXHTTPOperationQueueContext];
                    [operation addObserver:self forKeyPath:@"bytesSent" options:0 context:JXHTTPOperationQueueContext];
                    [operation addObserver:self forKeyPath:@"response" options:0 context:JXHTTPOperationQueueContext];

                    [self.observedOperationSet addObject:operation];
                }
            });
        }

        for (JXHTTPOperation *operation in removedArray) {
            if (![operation isKindOfClass:[JXHTTPOperation class]])
                continue;
            
            dispatch_sync(self.observationQueue, ^{
                BOOL observed = [self.observedOperationSet containsObject:operation];
                
                if (observed) {
                    [operation removeObserver:self forKeyPath:@"bytesReceived" context:JXHTTPOperationQueueContext];
                    [operation removeObserver:self forKeyPath:@"bytesSent" context:JXHTTPOperationQueueContext];
                    [operation removeObserver:self forKeyPath:@"response" context:JXHTTPOperationQueueContext];

                    [self.observedOperationSet removeObject:operation];
                }
            });

            if (operation.isCancelled) {
                NSString *uniqueString = [NSString stringWithString:operation.uniqueString];

                dispatch_barrier_async(self.progressMathQueue, ^{
                    [blockSelf.bytesReceivedPerOperation removeObjectForKey:uniqueString];
                    [blockSelf.bytesSentPerOperation removeObjectForKey:uniqueString];
                });
            }
        }
        
        if (oldCount > 0 && newCount < 1) {
            self.finishDate = now;
            [self performDelegateMethod:@selector(httpOperationQueueDidFinish:)];
        }

        return;
    }

    if ([keyPath isEqualToString:@"response"]) {
        JXHTTPOperation *operation = object;
        long long length = [operation.response expectedContentLength];

        if (length && length != NSURLResponseUnknownLength) {
            NSNumber *expectedDown = @(length);
            NSString *uniqueString = [NSString stringWithString:operation.uniqueString];

            dispatch_barrier_async(self.progressMathQueue, ^{
                [blockSelf.expectedDownloadBytesPerOperation setObject:expectedDown forKey:uniqueString];
            });
        }

        return;
    }

    if ([keyPath isEqualToString:@"bytesReceived"]) {
        JXHTTPOperation *operation = (JXHTTPOperation *)object;

        long long bytesReceived = operation.bytesReceived;
        NSString *uniqueString = [NSString stringWithString:operation.uniqueString];

        dispatch_barrier_async(self.progressMathQueue, ^{
            [blockSelf.bytesReceivedPerOperation setObject:@(bytesReceived) forKey:uniqueString];
        });

        dispatch_sync(self.progressMathQueue, ^{
            long long bytesDownloaded = 0LL;
            long long expectedDownloadBytes = 0LL;

            for (NSString *opID in [self.bytesReceivedPerOperation allKeys]) {
                bytesDownloaded += [[self.bytesReceivedPerOperation objectForKey:opID] longLongValue];
            }

            for (NSString *opID in [self.expectedDownloadBytesPerOperation allKeys]) {
                expectedDownloadBytes += [[self.expectedDownloadBytesPerOperation objectForKey:opID] longLongValue];
            }

            dispatch_barrier_async(self.progressMathQueue, ^{
                blockSelf.bytesDownloaded = @(bytesDownloaded);
                blockSelf.expectedDownloadBytes = @(expectedDownloadBytes);
                blockSelf.downloadProgress = expectedDownloadBytes ? @(bytesDownloaded / (float)expectedDownloadBytes) : @0.0f;
                [blockSelf performDelegateMethod:@selector(httpOperationQueueDidUpload:)];
                [blockSelf performDelegateMethod:@selector(httpOperationQueueDidMakeProgress:)];
            });
        });

        return;
    }

    if ([keyPath isEqualToString:@"bytesSent"]) {
        JXHTTPOperation *operation = (JXHTTPOperation *)object;

        long long bytesSent = operation.bytesSent;
        NSString *uniqueString = [NSString stringWithString:operation.uniqueString];

        dispatch_barrier_async(self.progressMathQueue, ^{
            [blockSelf.bytesSentPerOperation setObject:@(bytesSent) forKey:uniqueString];
        });

        dispatch_sync(self.progressMathQueue, ^{
            long long bytesUploaded = 0LL;
            long long expectedUploadBytes = 0LL;

            for (NSString *opID in [self.bytesSentPerOperation allKeys]) {
                bytesUploaded += [[self.bytesSentPerOperation objectForKey:opID] longLongValue];
            }

            for (NSString *opID in [self.expectedUploadBytesPerOperation allKeys]) {
                expectedUploadBytes += [[self.expectedUploadBytesPerOperation objectForKey:opID] longLongValue];
            }

            dispatch_barrier_async(self.progressMathQueue, ^{
                blockSelf.bytesUploaded = @(bytesUploaded);
                blockSelf.expectedUploadBytes = @(expectedUploadBytes);
                blockSelf.uploadProgress = expectedUploadBytes ? @(bytesUploaded / (float)expectedUploadBytes) : @0.0f;
                [blockSelf performDelegateMethod:@selector(httpOperationQueueDidDownload:)];
                [blockSelf performDelegateMethod:@selector(httpOperationQueueDidMakeProgress:)];
            });
        });

        return;
    }
}

@end
