#import "JXHTTPOperation.h"
#import "JXURLEncoding.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
static NSInteger operationCount = 0;
#endif

static void * JXHTTPOperationKVOContext = &JXHTTPOperationKVOContext;

@interface JXHTTPOperation ()
@property (retain) NSURLAuthenticationChallenge *authenticationChallenge;
@property (retain) NSNumber *downloadProgress;
@property (retain) NSNumber *uploadProgress;
@property (retain) NSString *uniqueIDString;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0
@property (assign) BOOL didIncrementOperationCount;
@property (assign) BOOL didDecrementOperationCount;
#endif
@end

@implementation JXHTTPOperation

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"responseDataFilePath" context:JXHTTPOperationKVOContext];

    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0
    [self decrementOperationCount];
    #endif
    
    [_authenticationChallenge release];
    [_requestBody release];
    [_downloadProgress release];
    [_uploadProgress release];
    [_responseDataFilePath release];
    [_uniqueIDString release];
    [_userObject release];
    [_credential release];
    
    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.downloadProgress = [NSNumber numberWithFloat:0.0f];
        self.uploadProgress = [NSNumber numberWithFloat:0.0f];
        self.uniqueIDString = [[NSProcessInfo processInfo] globallyUniqueString];
        self.authenticationChallenge = nil;
        self.responseDataFilePath = nil;
        self.credential = nil;
        self.userObject = nil;
        self.useCredentialStorage = YES;

        #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0
        self.didIncrementOperationCount = NO;
        self.didDecrementOperationCount = NO;
        self.updatesNetworkActivityIndicator = YES;
        #endif
        
        [self addObserver:self forKeyPath:@"responseDataFilePath" options:0 context:JXHTTPOperationKVOContext];
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
    if (self.isCancelled || !self.delegate)
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

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0
- (void)incrementOperationCount
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(incrementOperationCount) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if (self.didIncrementOperationCount || !self.updatesNetworkActivityIndicator)
        return;

    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(++operationCount > 0)];

    self.didIncrementOperationCount = YES;
}

- (void)decrementOperationCount
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(decrementOperationCount) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if (self.didDecrementOperationCount || !self.updatesNetworkActivityIndicator || !self.didIncrementOperationCount)
        return;

    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(--operationCount > 0)];
    
    self.didDecrementOperationCount = YES;
}
#endif

#pragma mark -
#pragma mark <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != JXHTTPOperationKVOContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if (object == self && [keyPath isEqualToString:@"responseDataFilePath"]) {
        if (self.isCancelled || self.isExecuting || self.isFinished)
            return;
        
        if ([self.responseDataFilePath length]) {
            self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.responseDataFilePath append:NO];
        } else {
            self.outputStream = [NSOutputStream outputStreamToMemory];
        }
        
        return;
    }
}

#pragma mark -
#pragma mark JXURLConnectionOperation

- (void)main
{
    [self performDelegateMethod:@selector(httpOperationWillStart:)];

    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0
    [self incrementOperationCount];
    #endif
    
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
        if (expectedLength > 0LL && expectedLength != NSURLResponseUnknownLength)
            [self.request setValue:[NSString stringWithFormat:@"%qi", expectedLength] forHTTPHeaderField:@"Content-Length"];
    }
    
    [super main];
}

- (void)finish
{
    [self performDelegateMethod:@selector(httpOperationDidFinish:)];

    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0
    [self decrementOperationCount];
    #endif
    
    [super finish];
}

#pragma mark -
#pragma mark <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError
{
    [super connection:connection didFailWithError:connectionError];
    
    [self performDelegateMethod:@selector(httpOperationDidFail:)];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return self.useCredentialStorage;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    self.authenticationChallenge = challenge;

    SEL delegateMethodSelector = @selector(httpOperationWillSendRequestForAuthenticationChallenge:);
    BOOL delegateRespondsToMethod = self.delegate && [self.delegate respondsToSelector:delegateMethodSelector];
    
    if (self.isCancelled || (!delegateRespondsToMethod && !self.credential)) {
        [[self.authenticationChallenge sender] cancelAuthenticationChallenge:self.authenticationChallenge];
        return;
    }
    
    if (delegateRespondsToMethod) {
        [self performDelegateMethod:delegateMethodSelector];
    } else {
        [[self.authenticationChallenge sender] useCredential:self.credential forAuthenticationChallenge:self.authenticationChallenge];
    }
}

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
    if (bytesExpected > 0LL && bytesExpected != NSURLResponseUnknownLength)
        self.downloadProgress = [NSNumber numberWithFloat:(self.bytesReceived / (float)bytesExpected)];
    
    [self performDelegateMethod:@selector(httpOperationDidReceiveData:)];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self.isCancelled) {
        [self finish];
        return;
    }
    
    if ([self.downloadProgress floatValue] != 1.0f)
        self.downloadProgress = [NSNumber numberWithFloat:1.0f];
    
    if ([self.uploadProgress floatValue] != 1.0f)
        self.uploadProgress = [NSNumber numberWithFloat:1.0f];
    
    [super connectionDidFinishLoading:connection];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytes totalBytesWritten:(NSInteger)total totalBytesExpectedToWrite:(NSInteger)expected
{    
    [super connection:connection didSendBodyData:bytes totalBytesWritten:total totalBytesExpectedToWrite:expected];
    
    if (self.isCancelled)
        return;
    
    long long bytesExpected = [self.requestBody httpContentLength];
    if (bytesExpected > 0LL && bytesExpected != NSURLResponseUnknownLength)
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
