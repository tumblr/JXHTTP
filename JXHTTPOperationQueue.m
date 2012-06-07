#import "JXHTTPOperationQueue.h"
#import "JXHTTPOperation.h"

@interface JXHTTPOperationQueue ()
@property (nonatomic, retain) NSMutableDictionary *bytesReceivedPerOperation;
@property (nonatomic, retain) NSMutableDictionary *bytesSentPerOperation;
@property (nonatomic, retain) NSMutableDictionary *expectedDownloadBytesPerOperation;
@property (nonatomic, retain) NSMutableDictionary *expectedUploadBytesPerOperation;
@property (nonatomic, retain) NSNumber *downloadProgress;
@property (nonatomic, retain) NSNumber *uploadProgress;
- (void)resetProgress;
@end

@implementation JXHTTPOperationQueue

@synthesize downloadProgress, uploadProgress, delegate, bytesReceivedPerOperation, bytesSentPerOperation,
            performsDelegateMethodsOnMainThread, expectedDownloadBytesPerOperation, expectedUploadBytesPerOperation;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{    
    [self removeObserver:self forKeyPath:@"operationCount"];
    [self removeObserver:self forKeyPath:@"operations"];
    
    self.delegate = nil;
    
    [downloadProgress release];
    [uploadProgress release];
    [bytesReceivedPerOperation release];
    [bytesSentPerOperation release];
    
    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        [self resetProgress];
        
        [self addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"operations" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)  context:NULL];
    }
    return self;
}

+ (id)queue
{
    return [[[self alloc] init] autorelease];
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

- (void)resetProgress
{
    self.bytesReceivedPerOperation = [NSMutableDictionary dictionary];
    self.bytesSentPerOperation = [NSMutableDictionary dictionary];
    self.expectedDownloadBytesPerOperation = [NSMutableDictionary dictionary];
    self.expectedUploadBytesPerOperation = [NSMutableDictionary dictionary];
    self.downloadProgress = [NSNumber numberWithFloat:0.0];
    self.uploadProgress = [NSNumber numberWithFloat:0.0];
}

#pragma mark -
#pragma mark <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"operationCount"]) {
        @synchronized (self) {
            if (self.operationCount > 0)
                return;
        }
        
        [self performDelegateMethod:@selector(httpOperationQueueDidFinish:)];
        
        [self resetProgress];
    }
    
    if (object == self && [keyPath isEqualToString:@"operations"]) {
        NSNumber *changeKind = [change objectForKey:NSKeyValueChangeKindKey];
        if ([changeKind unsignedIntegerValue] == NSKeyValueChangeSetting) {
            NSArray *insertedArray = [change objectForKey:NSKeyValueChangeNewKey];
            NSArray *removedArray = [change objectForKey:NSKeyValueChangeOldKey];
            
            for (JXHTTPOperation *operation in insertedArray) {
                if (![operation isKindOfClass:[JXHTTPOperation class]])
                    continue;
                
                [operation addObserver:self forKeyPath:@"bytesReceived" options:0 context:NULL];
                [operation addObserver:self forKeyPath:@"bytesSent" options:0 context:NULL];
                [operation addObserver:self forKeyPath:@"response.expectedContentLength" options:0 context:NULL];

                @synchronized (self) {
                    NSNumber *expectedUp = [NSNumber numberWithLongLong:operation.requestBody.httpContentLength];
                    [self.expectedUploadBytesPerOperation setObject:expectedUp forKey:operation.uniqueIDString];
                }
            }
            
            for (JXHTTPOperation *operation in removedArray) {
                if (![operation isKindOfClass:[JXHTTPOperation class]])
                    continue;
                
                [operation removeObserver:self forKeyPath:@"bytesReceived"];
                [operation removeObserver:self forKeyPath:@"bytesSent"];
                [operation removeObserver:self forKeyPath:@"response.expectedContentLength"];
                
                if (operation.isCancelled) {
                    @synchronized (self) {
                        [self.bytesReceivedPerOperation removeObjectForKey:operation.uniqueIDString];
                        [self.bytesSentPerOperation removeObjectForKey:operation.uniqueIDString];
                    }
                }
            }
        }  
    }
    
    if ([keyPath isEqualToString:@"response.expectedContentLength"]) {
        JXHTTPOperation *operation = object;
        long long length = [operation responseExpectedContentLength];

        @synchronized (self) {
            if (length && length != NSURLResponseUnknownLength) {
                NSNumber *expectedDown = [NSNumber numberWithLongLong:length];
                [self.expectedDownloadBytesPerOperation setObject:expectedDown forKey:operation.uniqueIDString];
            }
        }
    }
    
    if ([keyPath isEqualToString:@"bytesReceived"]) {
        @synchronized (self) {
            JXHTTPOperation *operation = (JXHTTPOperation *)object;
            [self.bytesReceivedPerOperation setObject:[NSNumber numberWithLongLong:operation.bytesReceived] forKey:operation.uniqueIDString];
            
            long long bytesDownloaded = 0;            
            for (NSString *opID in [self.bytesReceivedPerOperation allKeys]) {
                bytesDownloaded += [[self.bytesReceivedPerOperation objectForKey:opID] longLongValue];
            }
            
            long long expectedDownloadBytes = 0;
            for (NSString *opID in [self.expectedDownloadBytesPerOperation allKeys]) {
                expectedDownloadBytes += [[self.expectedDownloadBytesPerOperation objectForKey:opID] longLongValue];
            }
            
            self.downloadProgress = [NSNumber numberWithFloat:expectedDownloadBytes ? (bytesDownloaded / (float)expectedDownloadBytes) : 0.0];
        }
        
        [self performDelegateMethod:@selector(httpOperationQueueDidMakeProgress:)];
    }
    
    if ([keyPath isEqualToString:@"bytesSent"]) {
        @synchronized (self) {
            JXHTTPOperation *operation = (JXHTTPOperation *)object;
            [self.bytesSentPerOperation setObject:[NSNumber numberWithLongLong:operation.bytesSent] forKey:operation.uniqueIDString];
            
            long long bytesUploaded = 0;
            for (NSString *opID in [self.bytesSentPerOperation allKeys]) {
                bytesUploaded += [[self.bytesSentPerOperation objectForKey:opID] longLongValue];
            }
            
            long long expectedUploadBytes = 0;
            for (NSString *opID in [self.expectedUploadBytesPerOperation allKeys]) {
                expectedUploadBytes += [[self.expectedUploadBytesPerOperation objectForKey:opID] longLongValue];
            }
            
            self.uploadProgress = [NSNumber numberWithFloat:expectedUploadBytes ? (bytesUploaded / (float)expectedUploadBytes) : 0.0];
        }
        
        [self performDelegateMethod:@selector(httpOperationQueueDidMakeProgress:)];
    }
}

@end
