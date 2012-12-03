#import "JXURLConnectionOperation.h"

@interface JXURLConnectionOperation ()
@property (strong) NSURLConnection *connection;
@property (strong) NSMutableURLRequest *request;
@property (strong) NSURLResponse *response;
@property (strong) NSError *error;
@property (strong) NSThread *runLoopThread;
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
        self.runLoopThread = nil;

        self.bytesDownloaded = 0LL;
        self.bytesUploaded = 0LL;
    }
    return self;
}

- (id)initWithURL:(NSURL *)url
{
    if (self = [self init]) {
        self.request = [NSMutableURLRequest requestWithURL:url];
    }
    return self;
}

#pragma mark - NSOperation

- (void)main
{    
    if (self.isCancelled)
        return;

    self.runLoopThread = [NSThread currentThread];
    
    if (!self.outputStream)
        self.outputStream = [NSOutputStream outputStreamToMemory];

    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection start];

    if ([NSRunLoop currentRunLoop] == [NSRunLoop mainRunLoop])
        return;

    /*
     Removing this line can cause operations cancelled in-flight to lose the thread
     they're running on, preventing them from ever deallocating (especially many concurrent
     operations). The usual "adding an empty port" trick doesn't keep the thread alive.
     The downside is a small chance that the operation will take up to 5 seconds to
     dealloc after being cancelled. This should be considered a temporary solution.
     http://macsamurai.blogspot.com/2008/03/nsoperation-madness.html
     */
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];

    while(!self.isFinished) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

- (void)finish
{
    if (self.runLoopThread && self.runLoopThread != [NSThread currentThread]) {
        [self performSelector:@selector(finish) onThread:self.runLoopThread withObject:nil waitUntilDone:NO];
        return;
    }

    self.runLoopThread = nil;
    
    [self.connection cancel];
    [self.connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    [self.outputStream close];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    [super finish];
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
