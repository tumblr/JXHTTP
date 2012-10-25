@class JXHTTPOperation;

@protocol JXHTTPOperationDelegate <NSObject>
@optional
- (void)httpOperationWillStart:(JXHTTPOperation *)operation;
- (void)httpOperationWillNeedNewBodyStream:(JXHTTPOperation *)operation;
- (void)httpOperationWillSendRequestForAuthenticationChallenge:(JXHTTPOperation *)operation;
- (void)httpOperationDidReceiveResponse:(JXHTTPOperation *)operation;
- (void)httpOperationDidReceiveData:(JXHTTPOperation *)operation;
- (void)httpOperationDidSendData:(JXHTTPOperation *)operation;
- (void)httpOperationDidFinishLoading:(JXHTTPOperation *)operation;
- (void)httpOperationDidFail:(JXHTTPOperation *)operation;

//not yet functional
- (NSURLRequest *)httpOperation:(JXHTTPOperation *)operation willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response;
- (NSCachedURLResponse *)httpOperation:(JXHTTPOperation *)operation willCacheResponse:(NSCachedURLResponse *)cachedResponse;
@end
