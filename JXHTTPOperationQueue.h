#import "JXHTTPOperationQueueDelegate.h"

@interface JXHTTPOperationQueue : NSOperationQueue

@property (nonatomic, assign) NSObject <JXHTTPOperationQueueDelegate> *delegate;
@property (nonatomic, assign) BOOL performsDelegateMethodsOnMainThread;

@property (nonatomic, retain, readonly) NSNumber *downloadProgress;
@property (nonatomic, retain, readonly) NSNumber *uploadProgress;

+ (id)sharedQueue;
+ (id)queue;

@end
