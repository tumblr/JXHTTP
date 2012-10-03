#import "JXOperationQueue.h"
#import "JXHTTPOperationQueueDelegate.h"

@interface JXHTTPOperationQueue : JXOperationQueue

@property (nonatomic, assign) NSObject <JXHTTPOperationQueueDelegate> *delegate;
@property (nonatomic, assign) BOOL performsDelegateMethodsOnMainThread;

@property (nonatomic, retain, readonly) NSNumber *downloadProgress;
@property (nonatomic, retain, readonly) NSNumber *uploadProgress;

@property (nonatomic, retain, readonly) NSNumber *bytesDownloaded;
@property (nonatomic, retain, readonly) NSNumber *bytesUploaded;

@property (nonatomic, retain, readonly) NSNumber *expectedDownloadBytes;
@property (nonatomic, retain, readonly) NSNumber *expectedUploadBytes;

@end
