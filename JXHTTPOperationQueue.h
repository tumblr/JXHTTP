#import "JXOperationQueue.h"
#import "JXHTTPOperationQueueDelegate.h"

typedef void (^JXHTTPQueueBlock)(JXHTTPOperationQueue *queue);

@interface JXHTTPOperationQueue : JXOperationQueue

/// @name Core

@property (assign) NSObject <JXHTTPOperationQueueDelegate> *delegate;
@property (assign) BOOL performsDelegateMethodsOnMainThread;
@property (retain, readonly) NSString *uniqueString;

/// @name Timing

@property (retain, readonly) NSDate *startDate;
@property (retain, readonly) NSDate *finishDate;
@property (nonatomic, readonly) NSTimeInterval elapsedSeconds;

/// @name Progress

@property (retain, readonly) NSNumber *downloadProgress;
@property (retain, readonly) NSNumber *uploadProgress;

@property (retain, readonly) NSNumber *bytesDownloaded;
@property (retain, readonly) NSNumber *bytesUploaded;

@property (retain, readonly) NSNumber *expectedDownloadBytes;
@property (retain, readonly) NSNumber *expectedUploadBytes;

/// @name Blocks

@property (retain, readonly) NSOperationQueue *blockQueue;
@property (assign) BOOL performsBlocksOnMainThread;
@property (copy) JXHTTPQueueBlock willStartBlock;
@property (copy) JXHTTPQueueBlock didUploadBlock;
@property (copy) JXHTTPQueueBlock didDownloadBlock;
@property (copy) JXHTTPQueueBlock didMakeProgressBlock;
@property (copy) JXHTTPQueueBlock didFinishBlock;

@end
