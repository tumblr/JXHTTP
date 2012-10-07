#import "JXURLConnectionOperation.h"
#import "JXHTTPOperationDelegate.h"
#import "JXHTTPRequestBody.h"

/**
################################################################################
 Builds on the barebones `JXURLConnectionOperation` by adding the following:
 
 - Delegate methods via the <JXHTTPOperationDelegate> protocol.
 
 - A system for allowing any object to provide request body data via the
   <JXHTTPRequestBody> protocol and `NSInputStream`.
 
 - Network activity indicator management (status bar spinner).
 
 - Easy authorization with an `NSURLCredential` object.
 
 - Upload and download progress tracking with KVO notifications.
 */

@interface JXHTTPOperation : JXURLConnectionOperation

@property (assign) NSObject <JXHTTPOperationDelegate> *delegate;
@property (retain) NSObject <JXHTTPRequestBody> *requestBody;
@property (assign) BOOL performsDelegateMethodsOnMainThread;
@property (copy) NSString *responseDataFilePath;
@property (retain) NSURLCredential *credential;
@property (assign) BOOL useCredentialStorage;
@property (copy) NSArray *trustedHosts;
@property (assign) BOOL trustAllHosts;
@property (retain) id userObject;

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0
@property (assign) BOOL updatesNetworkActivityIndicator;
#endif

@property (retain, readonly) NSURLAuthenticationChallenge *authenticationChallenge;
@property (retain, readonly) NSString *uniqueIDString;
@property (retain, readonly) NSNumber *downloadProgress;
@property (retain, readonly) NSNumber *uploadProgress;

+ (id)withURLString:(NSString *)urlString;
+ (id)withURLString:(NSString *)urlString queryParameters:(NSDictionary *)parameters;

@end
