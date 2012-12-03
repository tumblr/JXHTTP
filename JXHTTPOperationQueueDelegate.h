@class JXHTTPOperationQueue;

@protocol JXHTTPOperationQueueDelegate <NSObject>
@optional
- (void)httpOperationQueueWillStart:(JXHTTPOperationQueue *)queue;
- (void)httpOperationQueueDidUpload:(JXHTTPOperationQueue *)queue;
- (void)httpOperationQueueDidDownload:(JXHTTPOperationQueue *)queue;
- (void)httpOperationQueueDidMakeProgress:(JXHTTPOperationQueue *)queue;
- (void)httpOperationQueueDidFinish:(JXHTTPOperationQueue *)queue;
@end
