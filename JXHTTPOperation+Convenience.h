#import "JXHTTPOperation.h"

@interface JXHTTPOperation (Convenience)

@property (nonatomic, assign) NSURLCacheStoragePolicy requestCachePolicy;
@property (nonatomic, assign) BOOL requestShouldUsePipelining;
@property (nonatomic, retain) NSURL *requestMainDocumentURL;
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;
@property (nonatomic, assign) NSURLRequestNetworkServiceType requestNetworkServiceType;
@property (nonatomic, retain) NSURL *requestURL;
@property (nonatomic, retain) NSDictionary *requestHeaders;
@property (nonatomic, retain) NSString *requestMethod;
@property (nonatomic, assign) BOOL requestShouldHandleCookies;

- (void)addValue:(NSString *)valueString forRequestHeader:(NSString *)headerFieldString;
- (void)setValue:(NSString *)valueString forRequestHeader:(NSString *)headerFieldString;

- (NSData *)responseData;
- (NSString *)responseString;
- (id)responseJSON;
- (NSDictionary *)responseHeaders;
- (NSInteger)responseStatusCode;
- (long long)responseExpectedContentLength;
- (NSString *)responseExpectedFileName;
- (NSString *)responseMIMEType;
- (NSString *)responseTextEncodingName;
- (NSURL *)responseURL;

@end