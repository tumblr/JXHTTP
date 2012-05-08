#import "JXOperation.h"

@interface JXOperation ()
@property (assign) BOOL isExecuting;
@property (assign) BOOL isFinished;
@end

@implementation JXOperation

@synthesize isExecuting, isFinished, startOnMainThread;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"isCancelled"];
    
    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.isExecuting = NO;
        self.isFinished = NO;
        
        [self addObserver:self forKeyPath:@"isCancelled" options:0 context:NULL];
    }
    return self;
}

#pragma mark -
#pragma mark <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"isCancelled"] && self.isCancelled)
        [self finish];
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

    @autoreleasepool {
        [self main];
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
