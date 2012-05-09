#import "JXOperation.h"

@interface JXOperation ()
@property (assign) BOOL isExecuting;
@property (assign) BOOL isFinished;
@end

@implementation JXOperation

@synthesize isExecuting, isFinished, startOnMainThread;

#pragma mark -
#pragma mark Initialization

- (id)init
{
    if ((self = [super init])) {
        self.isExecuting = NO;
        self.isFinished = NO;
    }
    return self;
}

#pragma mark -
#pragma mark NSOperation

- (void)start
{
    if (self.startOnMainThread && ![NSThread isMainThread]) {
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
    NSAssert(NO, @"subclasses must implement");

    [self finish];
}

- (void)finish
{
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    self.isExecuting = NO;
    self.isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end
