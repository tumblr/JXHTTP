#import "JXOperation.h"

@interface JXOperation ()
@property (assign) BOOL isExecuting;
@property (assign) BOOL isFinished;
@property (assign) dispatch_once_t startOnce;
@property (assign) dispatch_once_t finishOnce;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
@property (assign) UIBackgroundTaskIdentifier backgroundTaskID;
#endif
@end

@implementation JXOperation

#pragma mark - Initialization

- (void)dealloc
{
    [self endAppBackgroundTask];
}

- (id)init
{
    if (self = [super init]) {
        self.isExecuting = NO;
        self.isFinished = NO;
        self.startsOnMainThread = NO;
        self.continuesInAppBackground = NO;
        
        #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
        self.backgroundTaskID = UIBackgroundTaskInvalid;
        #endif
    }
    return self;
}

+ (id)operation
{
    return [[self alloc] init];
}

#pragma mark - NSOperation

- (void)start
{
    if (self.startsOnMainThread && ![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
        return;
    }
    
    if (!self.isReady || self.isCancelled || self.isExecuting || self.isFinished)
        return;
    
    dispatch_once(&_startOnce, ^{
        [self willChangeValueForKey:@"isExecuting"];
        self.isExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
        
        @autoreleasepool {
            [self main];
        }
    });
}

- (void)main
{
    NSAssert(NO, @"subclasses must implement and eventually call finish", nil);
}

#pragma mark - Public Methods

- (void)cancel
{
    [super cancel];

    [self finish];
}

- (void)finish
{
    // Only call willChange & didChange if `start` was called,
    // otherwise we risk crashing with concurrent operations.

    dispatch_once(&_finishOnce, ^{
        if (self.isExecuting) {
            [self willChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isFinished"];
            self.isExecuting = NO;
            self.isFinished = YES;
            [self didChangeValueForKey:@"isExecuting"];
            [self didChangeValueForKey:@"isFinished"];
        } else {
            self.isExecuting = NO;
            self.isFinished = YES;
        }
    });

    [self endAppBackgroundTask];
}

- (void)startAndWaitUntilFinished
{
    NSOperationQueue *tempQueue = [[NSOperationQueue alloc] init];
    [tempQueue addOperation:self];
    [tempQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - Accessors

- (BOOL)isConcurrent
{
    return YES;
}

- (void)setContinuesInAppBackground:(BOOL)shouldContinue
{
    _continuesInAppBackground = shouldContinue;

    if (self.continuesInAppBackground) {
        [self startAppBackgroundTask];
    } else {
        [self endAppBackgroundTask];
    }
}

#pragma mark - Private Methods

- (void)startAppBackgroundTask
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
    
    if (self.backgroundTaskID != UIBackgroundTaskInvalid || self.isFinished)
        return;
    
    UIBackgroundTaskIdentifier taskID = UIBackgroundTaskInvalid;
    taskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:taskID];
    }];

    self.backgroundTaskID = taskID;
    
    #endif
}

- (void)endAppBackgroundTask
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
    
    if (self.backgroundTaskID == UIBackgroundTaskInvalid)
        return;

    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];

    self.backgroundTaskID = UIBackgroundTaskInvalid;
    
    #endif
}

@end
