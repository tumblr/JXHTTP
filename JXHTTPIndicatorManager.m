#import "JXHTTPIndicatorManager.h"

@interface JXHTTPIndicatorManager ()
@property (nonatomic, assign) NSInteger activityCount;
@end

@implementation JXHTTPIndicatorManager

@synthesize activityCount;

+ (id)sharedManager
{
    static id sharedManager;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

- (void)incrementActivityCount
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.activityCount++;
    }];
}

- (void)decrementActivityCount
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.activityCount--;
    }];
}

- (NSInteger)activityCount
{
    if (!activityCount)
        activityCount = 0;

    return activityCount;
}

- (void)setActivityCount:(NSInteger)count
{
    activityCount = count;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:self.activityCount > 0];
}

@end
