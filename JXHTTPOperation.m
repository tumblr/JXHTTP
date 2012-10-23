#import "JXHTTPOperation.h"
#import "JXURLEncoding.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0
#import <UIKit/UIKit.h>
#endif

static NSUInteger JXHTTPOperationCount = 0;
static NSTimer * JXHTTPActivityTimer = nil;
static NSTimeInterval JXHTTPActivityTimerInterval = 0.618;

@interface JXHTTPOperation ()
@property (assign) BOOL didIncrementCount;
@property (retain) NSURLAuthenticationChallenge *authenticationChallenge;
@property (retain) NSNumber *downloadProgress;
@property (retain) NSNumber *uploadProgress;
@property (retain) NSString *uniqueString;
@property (retain) NSDate *startDate;
@property (retain) NSDate *finishDate;
@property (retain) NSOperationQueue *blockQueue;
@property (assign) dispatch_once_t incrementCountPredicate;
@property (assign) dispatch_once_t decrementCountPredicate;
@end

@implementation JXHTTPOperation

@synthesize responseDataFilePath = _responseDataFilePath;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [self decrementOperationCount];

    [_authenticationChallenge release];
    [_requestBody release];
    [_downloadProgress release];
    [_uploadProgress release];
    [_responseDataFilePath release];
    [_uniqueString release];
    [_userObject release];
    [_credential release];
    [_trustedHosts release];
    [_username release];
    [_password release];
    [_startDate release];
    [_finishDate release];

    [_willStartBlock release];
    [_willNeedNewBodyStreamBlock release];
    [_willSendRequestForAuthenticationChallengeBlock release];
    [_didReceiveResponseBlock release];
    [_didReceiveDataBlock release];
    [_didSendDataBlock release];
    [_didFinishLoadingBlock release];
    [_didFailBlock release];
    [_blockQueue release];

    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.downloadProgress = @0.0f;
        self.uploadProgress = @0.0f;

        self.uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];

        self.blockQueue = [[[NSOperationQueue alloc] init] autorelease];
        self.blockQueue.maxConcurrentOperationCount = 1;

        self.performsDelegateMethodsOnMainThread = NO;
        self.updatesNetworkActivityIndicator = YES;
        self.authenticationChallenge = nil;
        self.responseDataFilePath = nil;
        self.credential = nil;
        self.userObject = nil;
        self.didIncrementCount = NO;
        self.useCredentialStorage = YES;
        self.trustedHosts = nil;
        self.trustAllHosts = NO;
        self.username = nil;
        self.password = nil;
        self.startDate = nil;
        self.finishDate = nil;

        self.performsBlocksOnMainThread = NO;
        self.willStartBlock = nil;
        self.willNeedNewBodyStreamBlock = nil;
        self.willSendRequestForAuthenticationChallengeBlock = nil;
        self.didReceiveResponseBlock = nil;
        self.didReceiveDataBlock = nil;
        self.didSendDataBlock = nil;
        self.didFinishLoadingBlock = nil;
        self.didFailBlock = nil;
    }
    return self;
}

+ (id)withURLString:(NSString *)urlString
{
    return [[[self alloc] initWithURL:[NSURL URLWithString:urlString]] autorelease];
}

+ (id)withURLString:(NSString *)urlString queryParameters:(NSDictionary *)parameters
{
    NSString *string = urlString;

    if (parameters)
        string = [string stringByAppendingFormat:@"?%@", [JXURLEncoding encodedDictionary:parameters]];

    return [self withURLString:string];
}

#pragma mark -
#pragma mark Private Methods

- (void)performDelegateMethod:(SEL)selector
{
    __block JXHTTPBlock block = [self blockForSelector:selector];

    if (self.isCancelled || !(self.delegate || block))
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

    if (!block)
        return;

    if (self.performsBlocksOnMainThread) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (!self.isCancelled)
                block(self);
        }];
    } else {
        __block JXHTTPOperation *blockSelf = [self retain];
        [self.blockQueue addOperationWithBlock:^{
            if (!blockSelf.isCancelled)
                block(blockSelf);
            [blockSelf release];
        }];
    }
}

- (JXHTTPBlock)blockForSelector:(SEL)selector
{
    if (selector == @selector(httpOperationWillStart:))
        return self.willStartBlock;
    if (selector == @selector(httpOperationWillNeedNewBodyStream:))
        return self.willNeedNewBodyStreamBlock;
    if (selector == @selector(httpOperationWillSendRequestForAuthenticationChallenge:))
        return self.willSendRequestForAuthenticationChallengeBlock;
    if (selector == @selector(httpOperationDidReceiveResponse:))
        return self.didReceiveResponseBlock;
    if (selector == @selector(httpOperationDidReceiveData:))
        return self.didReceiveDataBlock;
    if (selector == @selector(httpOperationDidSendData:))
        return self.didSendDataBlock;
    if (selector == @selector(httpOperationDidFinishLoading:))
        return self.didFinishLoadingBlock;
    if (selector == @selector(httpOperationDidFail:))
        return self.didFailBlock;
    return nil;
}

#pragma mark -
#pragma mark Operation Count

+ (dispatch_queue_t)operationCountQueue
{
    static dispatch_queue_t operationCountQueue;
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
        operationCountQueue = dispatch_queue_create("JXHTTPOperation.operationCount", DISPATCH_QUEUE_SERIAL);
    });

    return operationCountQueue;
}

- (void)incrementOperationCount
{
    dispatch_once(&_incrementCountPredicate, ^{
        if (!self.updatesNetworkActivityIndicator)
            return;

        dispatch_async([JXHTTPOperation operationCountQueue], ^{
            ++JXHTTPOperationCount;
            [JXHTTPActivityTimer invalidate];
            [JXHTTPOperation toggleNetworkActivityVisible:@YES];
        });

        self.didIncrementCount = YES;
    });
}

- (void)decrementOperationCount
{
    if (!self.didIncrementCount)
        return;
    
    dispatch_once(&_decrementCountPredicate, ^{
        if (!self.updatesNetworkActivityIndicator)
            return;

        dispatch_async([JXHTTPOperation operationCountQueue], ^{
            if (--JXHTTPOperationCount < 1)
                [JXHTTPOperation restartActivityTimer];
        });
    });
}

+ (void)restartActivityTimer
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0

    [JXHTTPActivityTimer release];

    JXHTTPActivityTimer = [NSTimer timerWithTimeInterval:JXHTTPActivityTimerInterval
                                                  target:self
                                                selector:@selector(networkActivityTimerDidFire:)
                                                userInfo:nil
                                                 repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:JXHTTPActivityTimer forMode:NSRunLoopCommonModes];
    
    [JXHTTPActivityTimer retain];

    #endif
}

+ (void)networkActivityTimerDidFire:(NSTimer *)timer
{
    [JXHTTPOperation toggleNetworkActivityVisible:@NO];
}

+ (void)toggleNetworkActivityVisible:(NSNumber *)visibility
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0

    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(toggleNetworkActivityVisible:) withObject:visibility waitUntilDone:YES];
        return;
    }

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:[visibility boolValue]];

    #endif
}

#pragma mark -
#pragma mark Accessors

- (void)setResponseDataFilePath:(NSString *)filePath
{
    if (self.isExecuting || self.isFinished)
        return;

    [_responseDataFilePath release];
    _responseDataFilePath = [filePath copy];

    if ([self.responseDataFilePath length]) {
        self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.responseDataFilePath append:NO];
    } else {
        self.outputStream = nil;
    }
}

- (NSTimeInterval)elapsedSeconds
{
    if (self.startDate) {
        NSDate *endDate = self.finishDate ? self.finishDate : [NSDate date];
        return [endDate timeIntervalSinceDate:self.startDate];
    }
    return 0.0;
}

#pragma mark -
#pragma mark JXOperation

- (void)main
{
    if (self.isCancelled) {
        [super main];
        return;
    }

    self.startDate = [NSDate date];
    
    [self performDelegateMethod:@selector(httpOperationWillStart:)];

    [self incrementOperationCount];

    if (self.requestBody) {
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
    [self decrementOperationCount];
    
    [super finish];
}

#pragma mark -
#pragma mark <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError
{
    [super connection:connection didFailWithError:connectionError];

    if (self.isCancelled)
        return;

    self.finishDate = [NSDate date];

    [self decrementOperationCount];

    [self performDelegateMethod:@selector(httpOperationDidFail:)];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return self.useCredentialStorage;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (self.isCancelled) {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        return;
    }

    self.authenticationChallenge = challenge;

    [self performDelegateMethod:@selector(httpOperationWillSendRequestForAuthenticationChallenge:)];

    if (!self.credential && self.authenticationChallenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        BOOL trusted = NO;

        if (self.trustAllHosts) {
            trusted = YES;
        } else if (self.trustedHosts) {
            for (NSString *host in self.trustedHosts) {
                if ([host isEqualToString:self.authenticationChallenge.protectionSpace.host]) {
                    trusted = YES;
                    break;
                }
            }
        }

        if (trusted)
            self.credential = [NSURLCredential credentialForTrust:self.authenticationChallenge.protectionSpace.serverTrust];
    }

    if (!self.credential && self.username && self.password)
        self.credential = [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceForSession];

    if (self.credential) {
        [[self.authenticationChallenge sender] useCredential:self.credential forAuthenticationChallenge:self.authenticationChallenge];
        return;
    }

    [[self.authenticationChallenge sender] continueWithoutCredentialForAuthenticationChallenge:self.authenticationChallenge];
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
        self.downloadProgress = @(self.bytesReceived / (float)bytesExpected);

    [self performDelegateMethod:@selector(httpOperationDidReceiveData:)];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self.isCancelled) {
        [super connectionDidFinishLoading:connection];
        return;
    }

    self.finishDate = [NSDate date];

    if ([self.downloadProgress floatValue] != 1.0f)
        self.downloadProgress = @1.0f;

    if ([self.uploadProgress floatValue] != 1.0f)
        self.uploadProgress = @1.0f;

    [self decrementOperationCount];

    [self performDelegateMethod:@selector(httpOperationDidFinishLoading:)];

    [super connectionDidFinishLoading:connection];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytes totalBytesWritten:(NSInteger)bytesSent totalBytesExpectedToWrite:(NSInteger)bytesExpected
{
    [super connection:connection didSendBodyData:bytes totalBytesWritten:bytesSent totalBytesExpectedToWrite:bytesExpected];

    if (self.isCancelled)
        return;

    if (bytesExpected > 0LL && bytesExpected != NSURLResponseUnknownLength)
        self.uploadProgress = @(bytesSent / (float)bytesExpected);

    [self performDelegateMethod:@selector(httpOperationDidSendData:)];
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request
{
    if (self.isCancelled)
        return nil;

    [self performDelegateMethod:@selector(httpOperationWillNeedNewBodyStream:)];

    return [self.requestBody httpInputStream];
}

/*
 - (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response;
 - (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
 */

@end
