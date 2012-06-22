#import "JXOperationQueue.h"

@implementation JXOperationQueue

+ (id)queue
{
    return [[[self alloc] init] autorelease];
}

+ (id)sharedQueue
{
    static id sharedQueue;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        sharedQueue = [[self alloc] init];
    });
    
    return sharedQueue;
}

@end
