#import "JXHTTPOperation.h"

@interface JXHTTPOperation ()
@property (retain) NSNumber *downloadProgress;
@property (retain) NSNumber *uploadProgress;
@property (copy) NSString *responseDataFilePath;
@end

@implementation JXHTTPOperation

@synthesize delegate, performDelegateMethodsOnMainThread, requestBody, downloadProgress, uploadProgress, responseDataFilePath;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"requestBody"];
    
    [requestBody release];
    [downloadProgress release];
    [uploadProgress release];
    [responseDataFilePath release];

    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.downloadProgress = [NSNumber numberWithDouble:0.0];
        self.uploadProgress = [NSNumber numberWithDouble:0.0];  
        self.responseDataFilePath = nil;

        [self addObserver:self forKeyPath:@"requestBody" options:0 context:NULL];
    }
    return self;
}

+ (id)withURLString:(NSString *)urlString
{
    return [[[self alloc] initWithURL:[NSURL URLWithString:urlString]] autorelease];
}

#pragma mark -
#pragma mark Public Methods

- (void)streamResponseDataToFilePath:(NSString *)filePath append:(BOOL)append
{
    if (self.isCancelled || self.isExecuting || self.isFinished)
        return;

    self.responseDataFilePath = filePath;
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.responseDataFilePath append:append];
}

- (NSData *)responseData
{
    NSData *data = [self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    if (data)
        return data;
    
    return [NSData dataWithContentsOfMappedFile:self.responseDataFilePath];
}

- (NSString *)responseString
{
    return [[[NSString alloc] initWithData:[self responseData] encoding:NSUTF8StringEncoding] autorelease];
}

- (id)responseJSON
{
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:[self responseData] options:0 error:&error];
    if (error)
        NSLog(@"%@", error);
    return json;
}

- (NSDictionary *)responseHeaders
{
    return [(NSHTTPURLResponse *)self.response allHeaderFields];
}

- (NSInteger)responseStatusCode
{
    return [(NSHTTPURLResponse *)self.response statusCode];
}

#pragma mark -
#pragma mark Private Methods

- (void)performDelegateMethod:(SEL)selector
{
    if (self.performDelegateMethodsOnMainThread) {
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

#pragma mark -
#pragma mark <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"requestBody"] && self.requestBody) {
        NSInputStream *inputStream = [self.requestBody httpInputStream];
        if (!inputStream)
            return;

        self.request.HTTPBodyStream = inputStream;
        
        if ([[[self.request HTTPMethod] uppercaseString] isEqualToString:@"GET"])
            [self.request setHTTPMethod:@"POST"];        
        
        NSString *contentType = [self.requestBody httpContentType];
        if (![contentType length])
            contentType = @"application/octet-stream";
        
        [self.request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        long long expectedLength = [self.requestBody httpContentLength];
        if (expectedLength > 0 && expectedLength != NSURLResponseUnknownLength)
            [self.request setValue:[NSString stringWithFormat:@"%qi", expectedLength] forHTTPHeaderField:@"Content-Length"];
    }
}

#pragma mark -
#pragma mark JXURLConnectionOperation

- (void)main
{
    [self performDelegateMethod:@selector(httpOperationWillStart:)];
    
    [super main];
}

- (void)finish
{
    [self performDelegateMethod:@selector(httpOperationDidFinish:)];

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
    
    [self performDelegateMethod:@selector(httpOperationDidReceiveResponse:)];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [super connection:connection didReceiveData:data];
    
    long long bytesExpected = [self.response expectedContentLength];
    if (bytesExpected > 0 && bytesExpected != NSURLResponseUnknownLength)
        self.downloadProgress = [NSNumber numberWithDouble:(self.bytesReceived / (double)bytesExpected)];
    
    [self performDelegateMethod:@selector(httpOperationDidReceiveData:)];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self.downloadProgress doubleValue] != 1.0)
        self.downloadProgress = [NSNumber numberWithDouble:1.0];
    
    if ([self.uploadProgress doubleValue] != 1.0)
        self.uploadProgress = [NSNumber numberWithDouble:1.0];

    [super connectionDidFinishLoading:connection];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytes totalBytesWritten:(NSInteger)total totalBytesExpectedToWrite:(NSInteger)expected
{
    [super connection:connection didSendBodyData:bytes totalBytesWritten:total totalBytesExpectedToWrite:expected];

    long long bytesExpected = [self.requestBody httpContentLength];
    if (bytesExpected > 0 && bytesExpected != NSURLResponseUnknownLength)
        self.uploadProgress = [NSNumber numberWithDouble:(self.bytesSent / (double)bytesExpected)];
    
    [self performDelegateMethod:@selector(httpOperationDidSendData:)];
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request
{
    [self performDelegateMethod:@selector(httpOperationWillNeedNewBodyStream:)];

    return [self.requestBody httpInputStream];
}

/*
 - (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response;
 - (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse; 
 */

@end
