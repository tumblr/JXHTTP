@interface JXOperation : NSOperation

@property (assign, readonly) BOOL isExecuting;
@property (assign, readonly) BOOL isFinished;
@property (assign) BOOL startOnMainThread;

- (void)finish;

@end
