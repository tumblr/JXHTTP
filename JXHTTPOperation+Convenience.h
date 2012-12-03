#import "JXHTTPOperation.h"

@interface JXHTTPOperation (JXHTTPOperationConvenience)

@property (assign, nonatomic) NSURLCacheStoragePolicy requestCachePolicy;
@property (assign, nonatomic) BOOL requestShouldUsePipelining;
@property (strong, nonatomic) NSURL *requestMainDocumentURL;
@property (assign, nonatomic) NSTimeInterval requestTimeoutInterval;
@property (assign, nonatomic) NSURLRequestNetworkServiceType requestNetworkServiceType;
@property (strong, nonatomic) NSURL *requestURL;
@property (strong, nonatomic) NSDictionary *requestHeaders;
@property (strong, nonatomic) NSString *requestMethod;
@property (assign, nonatomic) BOOL requestShouldHandleCookies;

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