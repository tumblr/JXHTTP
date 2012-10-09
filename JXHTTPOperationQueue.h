#import "JXOperationQueue.h"
#import "JXHTTPOperationQueueDelegate.h"

@interface JXHTTPOperationQueue : JXOperationQueue

@property (assign) NSObject <JXHTTPOperationQueueDelegate> *delegate;
@property (assign) BOOL performsDelegateMethodsOnMainThread;
@property (retain, readonly) NSString *uniqueString;

@property (retain, readonly) NSNumber *downloadProgress;
@property (retain, readonly) NSNumber *uploadProgress;

@property (retain, readonly) NSNumber *bytesDownloaded;
@property (retain, readonly) NSNumber *bytesUploaded;

@property (retain, readonly) NSNumber *expectedDownloadBytes;
@property (retain, readonly) NSNumber *expectedUploadBytes;

@end
