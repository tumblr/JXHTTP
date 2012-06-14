#import "JXURLConnectionOperation.h"
#import "JXHTTPOperationDelegate.h"
#import "JXHTTPRequestBody.h"

@interface JXHTTPOperation : JXURLConnectionOperation

@property (assign) NSObject <JXHTTPOperationDelegate> *delegate;
@property (retain) NSObject <JXHTTPRequestBody> *requestBody;
@property (assign) BOOL performsDelegateMethodsOnMainThread;
@property (assign) BOOL updatesNetworkActivityIndicator;
@property (copy) NSString *responseDataFilePath;
@property (retain) id userObject;

@property (retain, readonly) NSString *uniqueIDString;
@property (retain, readonly) NSNumber *downloadProgress;
@property (retain, readonly) NSNumber *uploadProgress;

+ (id)withURLString:(NSString *)urlString;
+ (id)withURLString:(NSString *)urlString queryParameters:(NSDictionary *)parameters;

@end
