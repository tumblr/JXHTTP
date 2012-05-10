@class JXHTTPOperationQueue;

@protocol JXHTTPOperationQueueDelegate
@optional
- (void)httpOperationQueueDidMakeProgress:(JXHTTPOperationQueue *)queue;
- (void)httpOperationQueueDidFinish:(JXHTTPOperationQueue *)queue;
@end