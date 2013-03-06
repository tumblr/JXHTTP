@interface JXOperation : NSOperation

@property (assign, readonly) BOOL isExecuting;
@property (assign, readonly) BOOL isFinished;

@property (assign) BOOL startsOnMainThread;
@property (assign) BOOL continuesInAppBackground;

+ (instancetype)operation;

- (void)startAndWaitUntilFinished;
- (void)willFinish;
- (void)finish;

@end
