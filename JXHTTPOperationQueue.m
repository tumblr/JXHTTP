#import "JXHTTPOperationQueue.h"
#import "JXHTTPOperation.h"

static void * JXHTTPOperationQueueKVOContext = &JXHTTPOperationQueueKVOContext;

@interface JXHTTPOperationQueue ()
@property (nonatomic, retain) NSMutableDictionary *bytesReceivedPerOperation;
@property (nonatomic, retain) NSMutableDictionary *bytesSentPerOperation;
@property (nonatomic, retain) NSMutableDictionary *expectedDownloadBytesPerOperation;
@property (nonatomic, retain) NSMutableDictionary *expectedUploadBytesPerOperation;
@property (nonatomic, retain) NSMutableSet *observervedOperationIDs;
@property (nonatomic, retain) NSNumber *downloadProgress;
@property (nonatomic, retain) NSNumber *uploadProgress;
@property (nonatomic, assign) dispatch_queue_t progressQueue;
@property (nonatomic, assign) dispatch_queue_t observerQueue;
@end

@implementation JXHTTPOperationQueue

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{    
    [self removeObserver:self forKeyPath:@"operationCount" context:JXHTTPOperationQueueKVOContext];
    [self removeObserver:self forKeyPath:@"operations" context:JXHTTPOperationQueueKVOContext];
    
    self.delegate = nil;

    [_downloadProgress release];
    [_uploadProgress release];
    [_bytesReceivedPerOperation release];
    [_bytesSentPerOperation release];
    [_observervedOperationIDs release];
    dispatch_release(_progressQueue);
    dispatch_release(_observerQueue);
    
    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.progressQueue = dispatch_queue_create("com.justinouellette.JXHTTPOperationQueue.progress", DISPATCH_QUEUE_CONCURRENT);
        self.observerQueue = dispatch_queue_create("com.justinouellette.JXHTTPOperationQueue.observer", DISPATCH_QUEUE_CONCURRENT);
        
        self.observervedOperationIDs = [NSMutableSet set];

        [self addObserver:self forKeyPath:@"operationCount" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:JXHTTPOperationQueueKVOContext];
        [self addObserver:self forKeyPath:@"operations" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:JXHTTPOperationQueueKVOContext];
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
#pragma mark Private Methods

- (void)performDelegateMethod:(SEL)selector
{
    if (self.performsDelegateMethodsOnMainThread) {
        if ([self.delegate respondsToSelector:selector])
            [self.delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
    } else {
        if ([self.delegate respondsToSelector:selector])
            [self.delegate performSelector:selector onThread:[NSThread currentThread] withObject:self waitUntilDone:YES];
    }
}

#pragma mark -
#pragma mark <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != JXHTTPOperationQueueKVOContext)
        return;

    __block JXHTTPOperationQueue *blockSelf = self;
    
    if (object == self && [keyPath isEqualToString:@"operationCount"]) {
        NSNumber *newCount = [change objectForKey:NSKeyValueChangeNewKey];
        NSNumber *oldCount = [change objectForKey:NSKeyValueChangeOldKey];
        
        if ([oldCount integerValue] < 1 && [newCount integerValue] >= 1) {
            dispatch_barrier_async(self.progressQueue, ^{
                blockSelf.bytesReceivedPerOperation = [NSMutableDictionary dictionary];
                blockSelf.bytesSentPerOperation = [NSMutableDictionary dictionary];
                blockSelf.expectedDownloadBytesPerOperation = [NSMutableDictionary dictionary];
                blockSelf.expectedUploadBytesPerOperation = [NSMutableDictionary dictionary];
                blockSelf.downloadProgress = [NSNumber numberWithFloat:0.0f];
                blockSelf.uploadProgress = [NSNumber numberWithFloat:0.0f];
            });
        } else if ([oldCount integerValue] >= 1 && [newCount integerValue] < 1) {
            [self performDelegateMethod:@selector(httpOperationQueueDidFinish:)];
        }
        
        return;
    }
    
    if (object == self && [keyPath isEqualToString:@"operations"]) {
        if ([[change objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue] == NSKeyValueChangeSetting) {
            NSArray *insertedArray = [change objectForKey:NSKeyValueChangeNewKey];
            NSArray *removedArray = [change objectForKey:NSKeyValueChangeOldKey];
            
            for (JXHTTPOperation *operation in insertedArray) {
                if (![operation isKindOfClass:[JXHTTPOperation class]])
                    continue;

                NSNumber *expectedUp = [NSNumber numberWithLongLong:operation.requestBody.httpContentLength];
                NSString *uniqueIDString = [NSString stringWithString:operation.uniqueIDString];

                dispatch_barrier_async(self.progressQueue, ^{
                    [blockSelf.expectedUploadBytesPerOperation setObject:expectedUp forKey:uniqueIDString];
                });

                __block BOOL observing = NO;
                dispatch_sync(self.observerQueue, ^{
                    for (NSString *observedUniqueID in blockSelf.observervedOperationIDs) {
                        if ([uniqueIDString isEqualToString:observedUniqueID])
                            observing = YES;
                    }
                });

                if (!observing) {
                    [operation retain];

                    dispatch_barrier_async(self.observerQueue, ^{
                        [operation addObserver:blockSelf forKeyPath:@"bytesReceived" options:0 context:JXHTTPOperationQueueKVOContext];
                        [operation addObserver:blockSelf forKeyPath:@"bytesSent" options:0 context:JXHTTPOperationQueueKVOContext];
                        [operation addObserver:blockSelf forKeyPath:@"response" options:0 context:JXHTTPOperationQueueKVOContext];
                    });
                }
            }

            for (JXHTTPOperation *operation in removedArray) {
                if (![operation isKindOfClass:[JXHTTPOperation class]])
                    continue;

                NSString *uniqueIDString = [NSString stringWithString:operation.uniqueIDString];

                __block BOOL observing = NO;
                dispatch_sync(self.observerQueue, ^{
                    for (NSString *observedUniqueID in self.observervedOperationIDs) {
                        if ([uniqueIDString isEqualToString:observedUniqueID])
                            observing = YES;
                    }
                });

                if (observing) {
                    dispatch_barrier_async(self.observerQueue, ^{
                        [operation removeObserver:blockSelf forKeyPath:@"bytesReceived" context:JXHTTPOperationQueueKVOContext];
                        [operation removeObserver:blockSelf forKeyPath:@"bytesSent" context:JXHTTPOperationQueueKVOContext];
                        [operation removeObserver:blockSelf forKeyPath:@"response" context:JXHTTPOperationQueueKVOContext];
                        [operation release];
                    });
                }

                if (operation.isCancelled) {
                    dispatch_barrier_async(self.progressQueue, ^{
                        [blockSelf.bytesReceivedPerOperation removeObjectForKey:uniqueIDString];
                        [blockSelf.bytesSentPerOperation removeObjectForKey:uniqueIDString];
                    });
                }
            }
        }

        return;
    }
    
    if ([keyPath isEqualToString:@"response"]) {
        JXHTTPOperation *operation = object;
        long long length = [operation.response expectedContentLength];
        
        if (length && length != NSURLResponseUnknownLength) {
            NSNumber *expectedDown = [NSNumber numberWithLongLong:length];
            NSString *uniqueIDString = [NSString stringWithString:operation.uniqueIDString];

            dispatch_barrier_async(self.progressQueue, ^{
                [blockSelf.expectedDownloadBytesPerOperation setObject:expectedDown forKey:uniqueIDString];
            });
        }

        return;
    }
    
    if ([keyPath isEqualToString:@"bytesReceived"]) {
        JXHTTPOperation *operation = (JXHTTPOperation *)object;
        
        long long bytesReceived = operation.bytesReceived;
        NSString *uniqueIDString = [NSString stringWithString:operation.uniqueIDString];

        dispatch_barrier_async(self.progressQueue, ^{
            [blockSelf.bytesReceivedPerOperation setObject:[NSNumber numberWithLongLong:bytesReceived] forKey:uniqueIDString];
        });
        
        __block long long bytesDownloaded = 0LL;
        __block long long expectedDownloadBytes = 0LL;

        dispatch_sync(self.progressQueue, ^{
            for (NSString *opID in [blockSelf.bytesReceivedPerOperation allKeys]) {
                bytesDownloaded += [[blockSelf.bytesReceivedPerOperation objectForKey:opID] longLongValue];
            }

            for (NSString *opID in [blockSelf.expectedDownloadBytesPerOperation allKeys]) {
                expectedDownloadBytes += [[blockSelf.expectedDownloadBytesPerOperation objectForKey:opID] longLongValue];
            }
        });

        dispatch_barrier_async(self.progressQueue, ^{
            blockSelf.downloadProgress = [NSNumber numberWithFloat:expectedDownloadBytes ? (bytesDownloaded / (float)expectedDownloadBytes) : 0.0f];
            [blockSelf performDelegateMethod:@selector(httpOperationQueueDidMakeProgress:)];
        });
        
        return;
    }
    
    if ([keyPath isEqualToString:@"bytesSent"]) {
        JXHTTPOperation *operation = (JXHTTPOperation *)object;

        long long bytesSent = operation.bytesSent;
        NSString *uniqueIDString = [NSString stringWithString:operation.uniqueIDString];
        
        dispatch_barrier_async(self.progressQueue, ^{
            [blockSelf.bytesSentPerOperation setObject:[NSNumber numberWithLongLong:bytesSent] forKey:uniqueIDString];
        });
        
        __block long long bytesUploaded = 0LL;
        __block long long expectedUploadBytes = 0LL;

        dispatch_sync(self.progressQueue, ^{
            for (NSString *opID in [blockSelf.bytesSentPerOperation allKeys]) {
                bytesUploaded += [[blockSelf.bytesSentPerOperation objectForKey:opID] longLongValue];
            }

            for (NSString *opID in [blockSelf.expectedUploadBytesPerOperation allKeys]) {
                expectedUploadBytes += [[blockSelf.expectedUploadBytesPerOperation objectForKey:opID] longLongValue];
            }
        });

        dispatch_barrier_async(self.progressQueue, ^{
            blockSelf.uploadProgress = [NSNumber numberWithFloat:expectedUploadBytes ? (bytesUploaded / (float)expectedUploadBytes) : 0.0f];
            [blockSelf performDelegateMethod:@selector(httpOperationQueueDidMakeProgress:)];
        });
        
        return;
    }
}

@end
