@class JXHTTPOperation;

@protocol JXHTTPDelegate <NSObject>
@optional
- (void)httpOperationWillStart:(JXHTTPOperation *)operation;
- (void)httpOperationWillNeedNewBodyStream:(JXHTTPOperation *)operation;
- (void)httpOperationDidReceiveResponse:(JXHTTPOperation *)operation;
- (void)httpOperationDidReceiveData:(JXHTTPOperation *)operation;
- (void)httpOperationDidSendData:(JXHTTPOperation *)operation;
- (void)httpOperationDidFinish:(JXHTTPOperation *)operation;
- (void)httpOperationDidFail:(JXHTTPOperation *)operation;
@end
