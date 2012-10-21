#import "JXOperation.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#endif

static void * JXOperationContext = &JXOperationContext;

@interface JXOperation ()
@property (assign) BOOL isExecuting;
@property (assign) BOOL isFinished;
@property (assign) BOOL didStart;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
@property (assign) UIBackgroundTaskIdentifier backgroundTaskID;
#endif
@end

@implementation JXOperation

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
    [self removeObserver:self forKeyPath:@"continuesInAppBackground" context:JXOperationContext];
    [self endAppBackgroundTask];
    #endif
    
    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.isExecuting = NO;
        self.isFinished = NO;
        self.startsOnMainThread = NO;

        #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
        self.continuesInAppBackground = NO;
        self.backgroundTaskID = UIBackgroundTaskInvalid;
        [self addObserver:self forKeyPath:@"continuesInAppBackground" options:0 context:JXOperationContext];
        #endif
    }
    return self;
}

+ (id)operation
{
    return [[[self alloc] init] autorelease];
}

#pragma mark -
#pragma mark NSOperation

- (void)start
{
    if (self.startsOnMainThread && ![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
        return;
    }
    
    if (!self.isReady || self.isCancelled || self.isExecuting || self.isFinished)
        return;
    
    [self willChangeValueForKey:@"isExecuting"];
    self.isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    @autoreleasepool {
        [self main];
    }
}

- (void)main
{
    NSAssert(NO, @"subclasses must implement and eventually call finish");
}

#pragma mark -
#pragma mark Public Methods

- (BOOL)isConcurrent
{
    return YES;
}

- (void)cancel
{
    [super cancel];
    [self finish];
}

- (void)finish
{
    if (self.isFinished)
        return;

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
    
    [self endAppBackgroundTask];
}

- (void)startAndWaitUntilFinished
{
    NSOperationQueue *tempQueue = [[NSOperationQueue alloc] init];
    [tempQueue addOperation:self];
    [tempQueue waitUntilAllOperationsAreFinished];
    [tempQueue release];
}

#pragma mark -
#pragma mark Private Methods

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

#pragma mark -
#pragma mark <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != JXOperationContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if (object == self && [keyPath isEqualToString:@"continuesInAppBackground"]) {
        if (self.continuesInAppBackground) {
            [self startAppBackgroundTask];
        } else {
            [self endAppBackgroundTask];
        }
        return;
    }
}

@end
