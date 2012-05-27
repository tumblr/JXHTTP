#import "JXHTTPOperation.h"
#import "JXURLEncoding.h"

static NSInteger operationCount = 0;

@interface JXHTTPOperation ()
@property (retain) NSNumber *downloadProgress;
@property (retain) NSNumber *uploadProgress;
@property (retain) NSString *uniqueIDString;
- (void)incrementOperationCount;
- (void)decrementOperationCount;
@end

@implementation JXHTTPOperation

@synthesize delegate, performsDelegateMethodsOnMainThread, requestBody, downloadProgress, uploadProgress, responseDataFilePath, uniqueIDString, userObject;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"responseDataFilePath"];
    
    [requestBody release];
    [downloadProgress release];
    [uploadProgress release];
    [responseDataFilePath release];
    [uniqueIDString release];
    [userObject release];

    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.downloadProgress = [NSNumber numberWithFloat:0.0];
        self.uploadProgress = [NSNumber numberWithFloat:0.0];
        self.uniqueIDString = [[NSProcessInfo processInfo] globallyUniqueString];
        self.responseDataFilePath = nil;
        self.userObject = nil;

        [self addObserver:self forKeyPath:@"responseDataFilePath" options:0 context:NULL];
    }
    return self;
}

+ (id)withURLString:(NSString *)urlString
{
    return [[[self alloc] initWithURL:[NSURL URLWithString:urlString]] autorelease];
}

+ (id)withURLString:(NSString *)urlString queryParameters:(NSDictionary *)parameters
{
    NSString *string = [NSString stringWithFormat:@"%@?%@", urlString, [JXURLEncoding encodedDictionary:parameters]];
    return [self withURLString:string];
}

#pragma mark -
#pragma mark Private Methods

- (void)performDelegateMethod:(SEL)selector
{
    if (self.isCancelled)
        return;

    if (self.performsDelegateMethodsOnMainThread) {
        if ([self.delegate respondsToSelector:selector])
            [self.delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
        
        if ([self.requestBody respondsToSelector:selector])
            [self.requestBody performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
    } else {
        if ([self.delegate respondsToSelector:selector])
            [self.delegate performSelector:selector onThread:[NSThread currentThread] withObject:self waitUntilDone:YES];
        
        if ([self.requestBody respondsToSelector:selector])
            [self.requestBody performSelector:selector onThread:[NSThread currentThread] withObject:self waitUntilDone:YES];
    }
}

- (void)incrementOperationCount
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(++operationCount > 0)];
}

- (void)decrementOperationCount
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(--operationCount > 0)];
}

#pragma mark -
#pragma mark <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];

    if (object == self && [keyPath isEqualToString:@"responseDataFilePath"]) {
        if (self.isCancelled || self.isExecuting || self.isFinished)
            return;
        
        if ([self.responseDataFilePath length]) {
            self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.responseDataFilePath append:NO];
        } else {
            self.outputStream = [NSOutputStream outputStreamToMemory];
        }
    }
}

#pragma mark -
#pragma mark JXURLConnectionOperation

- (void)main
{
    [self performDelegateMethod:@selector(httpOperationWillStart:)];

    [self performSelectorOnMainThread:@selector(incrementOperationCount) withObject:nil waitUntilDone:NO];
    
    if (self.requestBody && !self.isCancelled) {
        NSInputStream *inputStream = [self.requestBody httpInputStream];
        if (inputStream)
            self.request.HTTPBodyStream = inputStream;

        if ([[[self.request HTTPMethod] uppercaseString] isEqualToString:@"GET"])
            [self.request setHTTPMethod:@"POST"];        
        
        NSString *contentType = [self.requestBody httpContentType];
        if (![contentType length])
            contentType = @"application/octet-stream";

        if (![self.request valueForHTTPHeaderField:@"Content-Type"])
            [self.request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        long long expectedLength = [self.requestBody httpContentLength];
        if (expectedLength > 0 && expectedLength != NSURLResponseUnknownLength)
            [self.request setValue:[NSString stringWithFormat:@"%qi", expectedLength] forHTTPHeaderField:@"Content-Length"];
    }

    [super main];
}

- (void)finish
{
    [self performDelegateMethod:@selector(httpOperationDidFinish:)];
    
    [self performSelectorOnMainThread:@selector(decrementOperationCount) withObject:nil waitUntilDone:NO];

    [super finish];
}

#pragma mark -
#pragma mark <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError
{
    [super connection:connection didFailWithError:connectionError];

    [self performDelegateMethod:@selector(httpOperationDidFail:)];
}

/*
 - (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection;
 - (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
 */

#pragma mark -
#pragma mark <NSURLConnectionDataDelegate>

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
    [super connection:connection didReceiveResponse:urlResponse];
    
    if (self.isCancelled)
        return;
    
    [self performDelegateMethod:@selector(httpOperationDidReceiveResponse:)];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [super connection:connection didReceiveData:data];
    
    if (self.isCancelled)
        return;
    
    long long bytesExpected = [self.response expectedContentLength];
    if (bytesExpected > 0 && bytesExpected != NSURLResponseUnknownLength)
        self.downloadProgress = [NSNumber numberWithFloat:(self.bytesReceived / (float)bytesExpected)];
    
    [self performDelegateMethod:@selector(httpOperationDidReceiveData:)];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self.isCancelled) {
        [self finish];
        return;
    }
    
    if ([self.downloadProgress floatValue] != 1.0)
        self.downloadProgress = [NSNumber numberWithFloat:1.0];
    
    if ([self.uploadProgress floatValue] != 1.0)
        self.uploadProgress = [NSNumber numberWithFloat:1.0];

    [super connectionDidFinishLoading:connection];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytes totalBytesWritten:(NSInteger)total totalBytesExpectedToWrite:(NSInteger)expected
{    
    [super connection:connection didSendBodyData:bytes totalBytesWritten:total totalBytesExpectedToWrite:expected];
    
    if (self.isCancelled)
        return;

    long long bytesExpected = [self.requestBody httpContentLength];
    if (bytesExpected > 0 && bytesExpected != NSURLResponseUnknownLength)
        self.uploadProgress = [NSNumber numberWithFloat:(self.bytesSent / (float)bytesExpected)];
    
    [self performDelegateMethod:@selector(httpOperationDidSendData:)];
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request
{
    if (self.isCancelled) {
        [self finish];
        return nil;
    }
    
    [self performDelegateMethod:@selector(httpOperationWillNeedNewBodyStream:)];

    return [self.requestBody httpInputStream];
}

/*
 - (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response;
 - (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse; 
 */

@end
