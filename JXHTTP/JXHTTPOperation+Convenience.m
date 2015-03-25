#import "JXHTTPOperation+Convenience.h"
#import "JXHTTP.h"

@implementation JXHTTPOperation (JXHTTPOperationConvenience)

#pragma mark - Request

- (NSURLRequestCachePolicy)requestCachePolicy
{
    return self.request.cachePolicy;
}

- (void)setRequestCachePolicy:(NSURLRequestCachePolicy)requestCachePolicy
{
    self.request.cachePolicy = requestCachePolicy;
}

- (BOOL)requestShouldUsePipelining
{
    return self.request.HTTPShouldUsePipelining;
}

- (void)setRequestShouldUsePipelining:(BOOL)requestShouldUsePipelining
{
    self.request.HTTPShouldUsePipelining = requestShouldUsePipelining;
}

- (NSURL *)requestMainDocumentURL
{
    return self.request.mainDocumentURL;
}

- (void)setRequestMainDocumentURL:(NSURL *)requestMainDocumentURL
{
    self.request.mainDocumentURL = requestMainDocumentURL;
}

- (NSTimeInterval)requestTimeoutInterval
{
    return self.request.timeoutInterval;
}

- (void)setRequestTimeoutInterval:(NSTimeInterval)requestTimeoutInterval
{
    self.request.timeoutInterval = requestTimeoutInterval;
}

- (NSURLRequestNetworkServiceType)requestNetworkServiceType
{
    return self.request.networkServiceType;
}

- (void)setRequestNetworkServiceType:(NSURLRequestNetworkServiceType)requestNetworkServiceType
{
    self.request.networkServiceType = requestNetworkServiceType;
}

- (NSURL *)requestURL
{
    return self.request.URL;
}

- (void)setRequestURL:(NSURL *)requestURL
{
    self.request.URL = requestURL;
}

- (NSDictionary *)requestHeaders
{
    return [self.request allHTTPHeaderFields];
}

- (void)setRequestHeaders:(NSDictionary *)requestHeaders
{
    [self.request setAllHTTPHeaderFields:requestHeaders];
}

- (NSString *)requestMethod
{
    return self.request.HTTPMethod;
}

- (void)setRequestMethod:(NSString *)requestMethod
{
    self.request.HTTPMethod = requestMethod;
}

- (BOOL)requestShouldHandleCookies
{
    return self.request.HTTPShouldHandleCookies;
}

- (void)setRequestShouldHandleCookies:(BOOL)requestShouldHandleCookies
{
    self.request.HTTPShouldHandleCookies = requestShouldHandleCookies;
}

- (void)addValue:(NSString *)valueString forRequestHeader:(NSString *)headerFieldString
{
    [self.request addValue:valueString forHTTPHeaderField:headerFieldString];
}

- (void)setValue:(NSString *)valueString forRequestHeader:(NSString *)headerFieldString
{
    [self.request setValue:valueString forHTTPHeaderField:headerFieldString];
}

#pragma mark - Response

- (NSData *)responseData
{
    NSData *data = [self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    if (data)
        return data;

    if ([self.responseDataFilePath length]) {
        NSError *error = nil;
        data = [[NSData alloc] initWithContentsOfFile:self.responseDataFilePath
                                              options:NSDataReadingMappedIfSafe
                                                error:&error];
        JXError(error);
    } else {
        data = nil;
    }

    return data;
}

- (NSString *)responseString
{
    NSData *data = [self responseData];
    if (![data length])
        return nil;

    NSStringEncoding encoding = NSUTF8StringEncoding;

    if (self.response.textEncodingName) {
        CFStringRef encodingName = (__bridge CFStringRef)self.response.textEncodingName;
        CFStringEncoding responseEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName);
        if (responseEncoding != kCFStringEncodingInvalidId)
            encoding = CFStringConvertEncodingToNSStringEncoding(responseEncoding);
    }

    return [[NSString alloc] initWithData:data encoding:encoding];
}

- (id)responseJSON
{
    NSData *data = [self responseData];
    if (!data)
        return nil;

    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    JXError(error);
    
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

- (NSString *)responseStatusString
{
    return [NSHTTPURLResponse localizedStringForStatusCode:[self responseStatusCode]];
}

- (long long)responseExpectedContentLength
{
    return self.response.expectedContentLength;
}

- (NSString *)responseExpectedFileName
{
    return self.response.suggestedFilename;
}

- (NSString *)responseMIMEType
{
    return self.response.MIMEType;
}

- (NSString *)responseTextEncodingName
{
    return self.response.textEncodingName;
}

- (NSURL *)responseURL
{
    return self.response.URL;
}

@end
