#import "JXOperation.h"

static void * JXOperationKVOContext;

@interface JXOperation ()
@property (assign) BOOL isExecuting;
@property (assign) BOOL isFinished;
@property (assign) UIBackgroundTaskIdentifier backgroundTaskID;
@end

@implementation JXOperation

@synthesize isExecuting, isFinished, startsOnMainThread, continuesInAppBackground, backgroundTaskID;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"continuesInAppBackground" context:JXOperationKVOContext];
    [self removeObserver:self forKeyPath:@"isCancelled" context:JXOperationKVOContext];
    [self removeObserver:self forKeyPath:@"isFinished" context:JXOperationKVOContext];
    
    if (self.backgroundTaskID != UIBackgroundTaskInvalid)
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];
    
    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.isExecuting = NO;
        self.isFinished = NO;
        self.startsOnMainThread = NO;
        self.continuesInAppBackground = NO;
        self.backgroundTaskID = UIBackgroundTaskInvalid;
        
        [self addObserver:self forKeyPath:@"continuesInAppBackground" options:0 context:JXOperationKVOContext];
        [self addObserver:self forKeyPath:@"isCancelled" options:0 context:JXOperationKVOContext];
        [self addObserver:self forKeyPath:@"isFinished" options:0 context:JXOperationKVOContext];
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
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }

    [self willChangeValueForKey:@"isExecuting"];
    self.isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    if (self.isCancelled) {
        [self finish];
    } else {
        @autoreleasepool {
            [self main];
        }
    }
}

- (void)main
{
    NSAssert(NO, @"subclasses must implement and eventually call finish");
}

#pragma mark -
#pragma mark Public Methods

- (void)finish
{
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    self.isExecuting = NO;
    self.isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)startAndWaitUntilFinished
{
    NSOperationQueue *tempQueue = [[NSOperationQueue alloc] init];
    [tempQueue addOperation:self];
    [tempQueue waitUntilAllOperationsAreFinished];
    [tempQueue release];
}

#pragma mark -
#pragma mark <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != JXOperationKVOContext)
        return;
    
    if (object == self && [keyPath isEqualToString:@"continuesInAppBackground"]) {
        if (self.continuesInAppBackground && self.backgroundTaskID == UIBackgroundTaskInvalid && !self.isCancelled) {
            UIBackgroundTaskIdentifier taskID = UIBackgroundTaskInvalid;
            taskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                [[UIApplication sharedApplication] endBackgroundTask:taskID];
            }];
            self.backgroundTaskID = taskID;
        } else if (!self.continuesInAppBackground && self.backgroundTaskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];
            self.backgroundTaskID = UIBackgroundTaskInvalid;
        }
        
        return;
    }
    
    if (object == self && ([keyPath isEqualToString:@"isFinished"] || [keyPath isEqualToString:@"isCancelled"])) {
        if ((self.isFinished || self.isCancelled) && self.backgroundTaskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];
            self.backgroundTaskID = UIBackgroundTaskInvalid;
        }
        
        return;
    }
}

@end
