@interface JXOperation : NSOperation

@property (assign, readonly) BOOL isExecuting;
@property (assign, readonly) BOOL isFinished;

@property (assign, nonatomic) BOOL startsOnMainThread;
@property (assign, nonatomic) BOOL continuesInAppBackground;

+ (instancetype)operation;

- (void)startAndWaitUntilFinished;
- (void)finish;

@end
