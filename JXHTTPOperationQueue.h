#import "JXHTTPOperationQueueDelegate.h"

@interface JXHTTPOperationQueue : NSOperationQueue

@property (retain, readonly) NSNumber *downloadProgress;
@property (retain, readonly) NSNumber *uploadProgress;
@property (assign) NSObject <JXHTTPOperationQueueDelegate> *delegate;

+ (id)queue;

@end
