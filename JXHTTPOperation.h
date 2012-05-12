#import "JXURLConnectionOperation.h"
#import "JXHTTPOperationDelegate.h"
#import "JXHTTPRequestBody.h"

@interface JXHTTPOperation : JXURLConnectionOperation

@property (assign) NSObject <JXHTTPOperationDelegate> *delegate;
@property (assign) BOOL performsDelegateMethodsOnMainThread;
@property (retain) NSObject <JXHTTPRequestBody> *requestBody;
@property (copy) NSString *responseDataFilePath;
@property (copy, readonly) NSString *uniqueIDString;
@property (retain, readonly) NSNumber *downloadProgress;
@property (retain, readonly) NSNumber *uploadProgress;

+ (id)withURLString:(NSString *)urlString;
+ (id)withURLString:(NSString *)urlString queryParameters:(NSDictionary *)parameters;

- (void)performSynchronously;

- (NSData *)responseData;
- (NSString *)responseString;
- (id)responseJSON;
- (NSDictionary *)responseHeaders;
- (NSInteger)responseStatusCode;

@end
