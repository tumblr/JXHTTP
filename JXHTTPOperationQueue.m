#import "JXHTTPOperationQueue.h"
#import "JXHTTPOperation.h"

@interface JXHTTPOperationQueue ()
@property (nonatomic, retain) NSMutableDictionary *bytesReceivedPerOperation;
@property (nonatomic, retain) NSMutableDictionary *bytesSentPerOperation;
@property (nonatomic, retain) NSNumber *downloadProgress;
@property (nonatomic, retain) NSNumber *uploadProgress;
@property (nonatomic, assign) long long expectedDownloadBytes;
@property (nonatomic, assign) long long expectedUploadBytes;
- (void)resetProgress;
@end

@implementation JXHTTPOperationQueue

@synthesize downloadProgress, uploadProgress, expectedDownloadBytes, expectedUploadBytes, delegate,
            bytesReceivedPerOperation, bytesSentPerOperation, performsDelegateMethodsOnMainThread;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"operationCount"];
    [self removeObserver:self forKeyPath:@"operations"]; 

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
    self.downloadProgress = [NSNumber numberWithFloat:0.0];
    self.uploadProgress = [NSNumber numberWithFloat:0.0];
    self.expectedDownloadBytes = 0;
    self.expectedUploadBytes = 0;
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

            for (JXHTTPOperation *op in insertedArray) {
                if (![op isKindOfClass:[JXHTTPOperation class]])
                    continue;

                [op addObserver:self forKeyPath:@"bytesReceived" options:0 context:NULL];
                [op addObserver:self forKeyPath:@"bytesSent" options:0 context:NULL];
                [op addObserver:self forKeyPath:@"response.expectedContentLength" options:0 context:NULL];
                
                @synchronized (self) {
                    self.expectedUploadBytes += op.requestBody.httpContentLength;
                }
            }
            
            for (JXHTTPOperation *op in removedArray) {
                if (![op isKindOfClass:[JXHTTPOperation class]])
                    continue;
                
                [op removeObserver:self forKeyPath:@"bytesReceived"];
                [op removeObserver:self forKeyPath:@"bytesSent"];
                [op removeObserver:self forKeyPath:@"response.expectedContentLength"];
                
                if (op.isCancelled) {
                    @synchronized (self) {
                        [self.bytesReceivedPerOperation removeObjectForKey:op.uniqueIDString];
                        [self.bytesSentPerOperation removeObjectForKey:op.uniqueIDString];
                    }
                }
            }
        }  
    }
    
    if ([keyPath isEqualToString:@"response.expectedContentLength"]) {
        long long length = [(NSHTTPURLResponse *)[object response] expectedContentLength];

        @synchronized (self) {
            if (length && length != NSURLResponseUnknownLength)
                self.expectedDownloadBytes += length;
        }
    }
    
    if ([keyPath isEqualToString:@"bytesReceived"] || [keyPath isEqualToString:@"bytesSent"]) {
        JXHTTPOperation *op = (JXHTTPOperation *)object;

        @synchronized (self) {            
            [self.bytesReceivedPerOperation setObject:[NSNumber numberWithLongLong:op.bytesReceived] forKey:op.uniqueIDString];
            [self.bytesSentPerOperation setObject:[NSNumber numberWithLongLong:op.bytesSent] forKey:op.uniqueIDString];

            long long bytesDownloaded = 0;
            long long bytesUploaded = 0;
            
            for (NSString *opID in [self.bytesReceivedPerOperation allKeys]) {
                bytesDownloaded += [[self.bytesReceivedPerOperation objectForKey:opID] longLongValue];
            }
            
            for (NSString *opID in [self.bytesSentPerOperation allKeys]) {
                bytesUploaded += [[self.bytesSentPerOperation objectForKey:opID] longLongValue];
            }
            
            self.downloadProgress = [NSNumber numberWithFloat:self.expectedDownloadBytes ? (bytesDownloaded / (float)self.expectedDownloadBytes) : 0.0];
            self.uploadProgress = [NSNumber numberWithFloat:self.expectedUploadBytes ? (bytesUploaded / (float)self.expectedUploadBytes) : 0.0];
        }
        
        [self performDelegateMethod:@selector(httpOperationQueueDidMakeProgress:)];
    }
}

@end
