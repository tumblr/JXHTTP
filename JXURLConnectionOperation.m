#import "JXURLConnectionOperation.h"

@interface JXURLConnectionOperation ()
@property (strong) NSURLConnection *connection;
@property (strong) NSMutableURLRequest *request;
@property (strong) NSURLResponse *response;
@property (strong) NSError *error;
@property (assign) long long bytesDownloaded;
@property (assign) long long bytesUploaded;
@end

@implementation JXURLConnectionOperation

#pragma mark - Initialization

- (id)init
{
    if (self = [super init]) {
        self.connection = nil;
        self.request = nil;
        self.response = nil;
        self.error = nil;
        self.outputStream = nil;

        self.bytesDownloaded = 0LL;
        self.bytesUploaded = 0LL;
    }
    return self;
}

- (id)initWithURL:(NSURL *)url
{
    if (self = [self init]) {
        self.request = [[NSMutableURLRequest alloc] initWithURL:url];
    }
    return self;
}

#pragma mark - NSOperation

- (void)main
{    
    if (self.isCancelled)
        return;
    
    if (!self.outputStream)
        self.outputStream = [NSOutputStream outputStreamToMemory];

    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection start];

    if ([NSRunLoop currentRunLoop] == [NSRunLoop mainRunLoop])
        return;

    while(!self.isFinished) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
    
    [self.connection cancel];
    [self.outputStream close];
    
    [self.connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
}

#pragma mark - <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError
{
    if (self.isCancelled)
        return;
    
    self.error = connectionError;

    [self finish];
}

#pragma mark - <NSURLConnectionDataDelegate>

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
            self.bytesDownloaded += bytesWritten;
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

    self.bytesUploaded += bytes;
}

@end
