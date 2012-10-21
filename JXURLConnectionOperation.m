#import "JXURLConnectionOperation.h"

@interface JXURLConnectionOperation ()
@property (retain) NSURLConnection *connection;
@property (retain) NSMutableURLRequest *request;
@property (retain) NSURLResponse *response;
@property (retain) NSError *error;
@property (assign) long long bytesReceived;
@property (assign) long long bytesSent;
@end

@implementation JXURLConnectionOperation

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    static int count = 0;
    NSLog(@"bye #%d // %p", count++, self);
    
    [_connection release];
    [_request release];
    [_response release];
    [_error release];
    [_outputStream release];

    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.connection = nil;
        self.request = nil;
        self.response = nil;
        self.error = nil;

        self.bytesReceived = 0LL;
        self.bytesSent = 0LL;
    }
    return self;
}

- (id)initWithURL:(NSURL *)url
{
    if ((self = [self init])) {
        self.request = [NSMutableURLRequest requestWithURL:url];
    }
    return self;
}

#pragma mark -
#pragma mark NSOperation

- (void)main
{    
    if (self.isCancelled)
        return;
    
    if (!self.outputStream)
        self.outputStream = [NSOutputStream outputStreamToMemory];

    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

    self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection start];

    if ([NSRunLoop currentRunLoop] == [NSRunLoop mainRunLoop])
        return;

    while(!self.isFinished) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

- (void)finish
{
    static int count = 0;
    NSLog(@"finish #%d // %p // thread %p", count++, self, [NSThread currentThread]);
    
    [self.connection cancel];
    [self.connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.connection = nil;

    [self.outputStream close];
    
    [super finish];
}

#pragma mark -
#pragma mark <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError
{
    if (self.isCancelled)
        return;
    
    self.error = connectionError;

    [self finish];
}

#pragma mark -
#pragma mark <NSURLConnectionDataDelegate>

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
    if (self.isCancelled)
        return;

    self.response = urlResponse;

    [self.outputStream open];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (self.isCancelled)
        return;
    
    if ([self.outputStream hasSpaceAvailable]) {
        NSInteger bytesWritten = [self.outputStream write:[data bytes] maxLength:[data length]];

        if (bytesWritten != -1)
            self.bytesReceived += bytesWritten;
    } else {
        [self finish];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self.isCancelled)
        return;

    [self finish];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytes totalBytesWritten:(NSInteger)total totalBytesExpectedToWrite:(NSInteger)expected
{
    if (self.isCancelled)
        return;

    self.bytesSent += bytes;
}

@end
