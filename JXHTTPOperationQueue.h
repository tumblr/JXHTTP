/**
 `JXHTTPOperationQueue` is an `NSOperationQueue` subclass and can be used to group
 multiple instances of <JXHTTPOperation> for progress tracking, timing, or cancellation.
 It provides blocks and delegate methods via the <JXHTTPOperationQueueDelegate> protocol.
 
 Any `NSOperation` subclass can be added to this queue, classes other than <JXHTTPOperation>
 are ignored.
 */

#import "JXHTTPOperationQueueDelegate.h"

typedef void (^JXHTTPQueueBlock)(JXHTTPOperationQueue *queue);

@interface JXHTTPOperationQueue : NSOperationQueue

/// @name Core

@property (weak) NSObject <JXHTTPOperationQueueDelegate> *delegate;
@property (strong, readonly) NSString *uniqueString;

/// @name Progress

@property (strong, readonly) NSNumber *downloadProgress;
@property (strong, readonly) NSNumber *uploadProgress;

@property (strong, readonly) NSNumber *bytesDownloaded;
@property (strong, readonly) NSNumber *bytesUploaded;

@property (strong, readonly) NSNumber *expectedDownloadBytes;
@property (strong, readonly) NSNumber *expectedUploadBytes;

/// @name Timing

@property (strong, readonly) NSDate *startDate;
@property (strong, readonly) NSDate *finishDate;
@property (readonly) NSTimeInterval elapsedSeconds;

/// @name Blocks

@property (assign) BOOL performsBlocksOnMainQueue;
@property (copy) JXHTTPQueueBlock willStartBlock;
@property (copy) JXHTTPQueueBlock willFinishBlock;
@property (copy) JXHTTPQueueBlock didStartBlock;
@property (copy) JXHTTPQueueBlock didUploadBlock;
@property (copy) JXHTTPQueueBlock didDownloadBlock;
@property (copy) JXHTTPQueueBlock didMakeProgressBlock;
@property (copy) JXHTTPQueueBlock didFinishBlock;

+ (instancetype)sharedQueue;

@end
