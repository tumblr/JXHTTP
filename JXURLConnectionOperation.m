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

@synthesize connection, request, response, error, bytesReceived, bytesSent, outputStream;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [connection release];
    [request release];
    [response release];
    [error release];
    [outputStream release];

    [super dealloc];
}

- (id)initWithURL:(NSURL *)url
{
    if ((self = [self init])) {
        self.request = [NSMutableURLRequest requestWithURL:url];
        self.bytesReceived = 0;
        self.bytesSent = 0;
    }
    return self;
}

#pragma mark -
#pragma mark NSOperation

- (void)main
{
    if (!self.outputStream)
        self.outputStream = [NSOutputStream outputStreamToMemory];
    
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

    self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection start];

    if ([NSRunLoop currentRunLoop] != [NSRunLoop mainRunLoop])
        [[NSRunLoop currentRunLoop] run];
}

- (void)finish
{
    [self.connection cancel];
    [self.connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    [self.outputStream close];
    
    [super finish];
}

#pragma mark -
#pragma mark <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError
{
    self.error = connectionError;

    [self finish];
}

#pragma mark -
#pragma mark <NSURLConnectionDataDelegate>

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
    self.response = urlResponse;

    [self.outputStream open];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
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
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytes totalBytesWritten:(NSInteger)total totalBytesExpectedToWrite:(NSInteger)expected
{
    self.bytesSent += bytes;
}

@end
