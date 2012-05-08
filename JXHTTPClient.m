#import "JXHTTPClient.h"

@implementation JXHTTPClient

@synthesize connectionQueue;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [connectionQueue release];

    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.connectionQueue = [[[NSOperationQueue alloc] init] autorelease];
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
    NSAssert(NO, @"under construction");
}

@end
