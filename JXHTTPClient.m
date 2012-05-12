#import "JXHTTPClient.h"
#import "JXHTTPOperation.h"
#import "JXHTTPOperationQueue.h"

@implementation JXHTTPClient

@synthesize operationQueue;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [operationQueue release];

    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.operationQueue = [[[JXHTTPOperationQueue alloc] init] autorelease];
    }
    return self;
}

+ (id)sharedClient
{
    static id sharedClient;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        sharedClient = [[self alloc] init];
    });
    
    return sharedClient;
}

#pragma mark -
#pragma mark Public Methods

- (void)performOperationSynchronously:(JXHTTPOperation *)httpOperation
{
    NSOperationQueue *tempQueue = [[NSOperationQueue alloc] init];
    [tempQueue addOperation:httpOperation];
    [tempQueue waitUntilAllOperationsAreFinished];
    [tempQueue release];
}

@end
