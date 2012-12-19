@class JXHTTPOperation;

@protocol JXHTTPOperationDelegate <NSObject>
@optional
- (void)httpOperationWillStart:(JXHTTPOperation *)operation;
- (void)httpOperationWillNeedNewBodyStream:(JXHTTPOperation *)operation;
- (void)httpOperationWillSendRequestForAuthenticationChallenge:(JXHTTPOperation *)operation;
- (void)httpOperationDidStart:(JXHTTPOperation *)operation;
- (void)httpOperationDidReceiveResponse:(JXHTTPOperation *)operation;
- (void)httpOperationDidReceiveData:(JXHTTPOperation *)operation;
- (void)httpOperationDidSendData:(JXHTTPOperation *)operation;
- (void)httpOperationDidFinishLoading:(JXHTTPOperation *)operation;
- (void)httpOperationDidFail:(JXHTTPOperation *)operation;
- (NSCachedURLResponse *)httpOperation:(JXHTTPOperation *)operation willCacheResponse:(NSCachedURLResponse *)cachedResponse;
- (NSURLRequest *)httpOperation:(JXHTTPOperation *)operation willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
@end
