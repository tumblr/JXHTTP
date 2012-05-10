#import "JXHTTPOperationQueue.h"
#import "JXHTTPOperation.h"

@interface JXHTTPOperationQueue ()
@property (retain) NSNumber *downloadProgress;
@property (retain) NSNumber *uploadProgress;
@end

@implementation JXHTTPOperationQueue

@synthesize downloadProgress, uploadProgress, delegate;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"operationCount"];
    [self removeObserver:self forKeyPath:@"operations"];    

    [downloadProgress release];
    [uploadProgress release];
    
    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.downloadProgress = [NSNumber numberWithFloat:0.0];
        self.uploadProgress = [NSNumber numberWithFloat:0.0];
    
        [self addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"operations" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)  context:NULL];
    }
    return self;
}

+ (id)queue
{
    return [[[self alloc] init] autorelease];
}

#pragma mark -
#pragma mark <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"operationCount"]) {
        if (self.operationCount == 0 && [self.delegate respondsToSelector:@selector(httpOperationQueueDidFinish:)])
            [self.delegate httpOperationQueueDidFinish:self];
    }
    
    if (object == self && [keyPath isEqualToString:@"operations"]) {
        NSNumber *changeKind = [change objectForKey:NSKeyValueChangeKindKey];
        if ([changeKind unsignedIntegerValue] == NSKeyValueChangeSetting) {
            NSArray *insertedArray = [change objectForKey:NSKeyValueChangeNewKey];
            NSArray *removedArray = [change objectForKey:NSKeyValueChangeOldKey];

            for (JXHTTPOperation *op in insertedArray) {
                [op addObserver:self forKeyPath:@"downloadProgress" options:0 context:NULL];
                [op addObserver:self forKeyPath:@"uploadProgress" options:0 context:NULL];
            }
            
            for (JXHTTPOperation *op in removedArray) {
                [op removeObserver:self forKeyPath:@"downloadProgress"];
                [op removeObserver:self forKeyPath:@"uploadProgress"];
            }
        }  
    }
    
    if ([keyPath isEqualToString:@"downloadProgress"] || [keyPath isEqualToString:@"uploadProgress"]) {
        long long expectedDownloadBytes = 0;
        long long expectedUploadBytes = 0;        
        long long bytesDownloaded = 0;
        long long bytesUploaded = 0;
        
        for (JXHTTPOperation *op in self.operations) {
            expectedDownloadBytes += op.response.expectedContentLength;
            expectedUploadBytes += op.requestBody.httpContentLength;            
            bytesDownloaded += op.bytesReceived;
            bytesUploaded += op.bytesSent;
        }

        self.downloadProgress = [NSNumber numberWithFloat:expectedDownloadBytes ? (bytesDownloaded / (float)expectedDownloadBytes) : 0.0];
        self.uploadProgress = [NSNumber numberWithFloat:expectedUploadBytes ? (bytesUploaded / (float)expectedUploadBytes) : 0.0];

        if ([self.delegate respondsToSelector:@selector(httpOperationQueueDidMakeProgress:)])
            [self.delegate httpOperationQueueDidMakeProgress:self];
    }
}

@end
