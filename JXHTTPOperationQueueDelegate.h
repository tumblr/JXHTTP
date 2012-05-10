@class JXHTTPOperationQueue;

@protocol JXHTTPOperationQueueDelegate
@optional
- (void)httpOperationQueueWillStart:(JXHTTPOperationQueue *)queue;
- (void)httpOperationQueueDidMakeProgress:(JXHTTPOperationQueue *)queue;
- (void)httpOperationQueueDidFinish:(JXHTTPOperationQueue *)queue;
@end