#import "JXURLConnectionOperation.h"
#import "JXHTTPDelegate.h"
#import "JXHTTPRequestBody.h"

@interface JXHTTPOperation : JXURLConnectionOperation

@property (assign) NSObject <JXHTTPDelegate> *delegate;
@property (assign) BOOL performDelegateMethodsOnMainThread;
@property (retain) NSObject <JXHTTPRequestBody> *requestBody;
@property (retain, readonly) NSNumber *downloadProgress;
@property (retain, readonly) NSNumber *uploadProgress;
@property (copy, readonly) NSString *responseDataFilePath;

+ (id)withURLString:(NSString *)urlString;

- (void)streamResponseDataToFilePath:(NSString *)filePath append:(BOOL)append;

- (NSData *)responseData;
- (NSString *)responseString;
- (id)responseJSON;
- (NSDictionary *)responseHeaders;
- (NSInteger)responseStatusCode;

@end
