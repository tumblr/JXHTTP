@interface JXHTTPIndicatorManager : NSObject

@property (nonatomic, assign, readonly) NSInteger activityCount;

+ (id)sharedManager;

- (void)incrementActivityCount;
- (void)decrementActivityCount;

@end
