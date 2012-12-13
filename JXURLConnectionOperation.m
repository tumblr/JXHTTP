#import "JXURLConnectionOperation.h"

@interface JXURLConnectionOperation ()
@property (strong) NSURLConnection *connection;
@property (strong) NSMutableURLRequest *request;
@property (strong) NSURLResponse *response;
@property (strong) NSError *connectionError;
@property (assign) long long bytesDownloaded;
@property (assign) long long bytesUploaded;
@end

@implementation JXURLConnectionOperation

#pragma mark - Initialization

- (void)dealloc
{
    [self.connection cancel];
    [self.outputStream close];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.connection = nil;
        self.request = nil;
        self.response = nil;
        self.connectionError = nil;
        self.outputStream = nil;

        self.bytesDownloaded = 0LL;
        self.bytesUploaded = 0LL;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    if (self = [self init]) {
        self.request = [[NSMutableURLRequest alloc] initWithURL:url];
    }
    return self;
}

#pragma mark - NSOperation

- (void)main
{
    if ([self isCancelled])
        return;
    
    [self performSelector:@selector(startStreamAndConnection)
                 onThread:[[self class] sharedThread]
               withObject:nil
            waitUntilDone:YES];
}

- (void)finish
{
    [super finish];
    
    [self performSelector:@selector(stopStreamAndConnection)
                 onThread:[[self class] sharedThread]
               withObject:nil
            waitUntilDone:YES];
}

#pragma mark - Siren Song

- (void)startStreamAndConnection
{
    if ([self isCancelled])
        return;
    
    if (!self.outputStream)
        self.outputStream = [[NSOutputStream alloc] initToMemory];

    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection start];
}

- (void)stopStreamAndConnection
{
    [self.connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection cancel];

    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.outputStream close];
}

+ (NSThread *)sharedThread
{
    static NSThread *thread = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        thread = [[NSThread alloc] initWithTarget:self selector:@selector(runLoop) object:nil];
        [thread start];
    });
    
    return thread;
}

+ (void)runLoop
{
    while ([[NSThread currentThread] isExecuting]) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
}

#pragma mark - <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError
{
    if ([self isCancelled])
        return;
    
    self.connectionError = connectionError;
    
    [self finish];
}

#pragma mark - <NSURLConnectionDataDelegate>

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
    if ([self isCancelled])
        return;

    self.response = urlResponse;
    
    [self.outputStream open];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ([self isCancelled])
        return;
    
    if ([self.outputStream hasSpaceAvailable]) {
        NSInteger bytesWritten = [self.outputStream write:[data bytes] maxLength:[data length]];
        
        if (bytesWritten != -1)
            self.bytesDownloaded += bytesWritten;
    }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytes totalBytesWritten:(NSInteger)total totalBytesExpectedToWrite:(NSInteger)expected
{
    if ([self isCancelled])
        return;
    
    self.bytesUploaded += bytes;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self isCancelled])
        return;

    [self finish];
}

@end
