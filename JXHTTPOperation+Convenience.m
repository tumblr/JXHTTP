#import "JXHTTPOperation+Convenience.h"

@implementation JXHTTPOperation (Convenience)

#pragma mark -
#pragma mark Request

- (NSURLCacheStoragePolicy)requestCachePolicy
{
    return self.request.cachePolicy;
}

- (void)setRequestCachePolicy:(NSURLCacheStoragePolicy)requestCachePolicy
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
    [self.request setValue:valueString forKey:headerFieldString];
}

#pragma mark -
#pragma mark Response

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

@end