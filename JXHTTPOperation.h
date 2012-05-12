#import "JXURLConnectionOperation.h"
#import "JXHTTPOperationDelegate.h"
#import "JXHTTPRequestBody.h"

@interface JXHTTPOperation : JXURLConnectionOperation

@property (assign) NSObject <JXHTTPOperationDelegate> *delegate;
@property (assign) BOOL performsDelegateMethodsOnMainThread;
@property (retain) NSObject <JXHTTPRequestBody> *requestBody;
@property (retain, readonly) NSNumber *downloadProgress;
@property (retain, readonly) NSNumber *uploadProgress;
@property (copy, readonly) NSString *responseDataFilePath;
@property (copy, readonly) NSString *uniqueIDString;

+ (id)withURLString:(NSString *)urlString;

- (void)streamResponseDataToFilePath:(NSString *)filePath append:(BOOL)append;

- (NSData *)responseData;
- (NSString *)responseString;
- (id)responseJSON;
- (NSDictionary *)responseHeaders;
- (NSInteger)responseStatusCode;

@end
