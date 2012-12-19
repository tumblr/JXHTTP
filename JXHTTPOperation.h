#import "JXURLConnectionOperation.h"
#import "JXHTTPOperationDelegate.h"
#import "JXHTTPRequestBody.h"

typedef void (^JXHTTPBlock)(JXHTTPOperation *operation);
typedef NSCachedURLResponse * (^JXHTTPCacheBlock)(JXHTTPOperation *operation, NSCachedURLResponse *response);
typedef NSURLRequest * (^JXHTTPRedirectBlock)(JXHTTPOperation *operation, NSURLRequest *request, NSURLResponse *response);

@interface JXHTTPOperation : JXURLConnectionOperation

// Core

@property (weak) NSObject <JXHTTPOperationDelegate> *delegate;
@property (strong) NSObject <JXHTTPRequestBody> *requestBody;
@property (strong) NSURLRequest *lastRequest;
@property (strong, readonly) NSString *uniqueString;
@property (copy, nonatomic) NSString *responseDataFilePath;
@property (assign) BOOL performsDelegateMethodsOnMainThread;
@property (strong) id userObject;

// Security

@property (strong, readonly) NSURLAuthenticationChallenge *authenticationChallenge;
@property (strong) NSURLCredential *credential;
@property (assign) BOOL useCredentialStorage;
@property (assign) BOOL trustAllHosts;
@property (copy) NSArray *trustedHosts;
@property (copy) NSString *username;
@property (copy) NSString *password;

// Progress

@property (strong, readonly) NSNumber *downloadProgress;
@property (strong, readonly) NSNumber *uploadProgress;
@property (assign) BOOL updatesNetworkActivityIndicator;

// Timing

@property (strong, readonly) NSDate *startDate;
@property (strong, readonly) NSDate *finishDate;
@property (readonly) NSTimeInterval elapsedSeconds;

// Blocks

@property (assign) BOOL performsBlocksOnMainThread;
@property (copy) JXHTTPBlock willStartBlock;
@property (copy) JXHTTPBlock willNeedNewBodyStreamBlock;
@property (copy) JXHTTPBlock willSendRequestForAuthenticationChallengeBlock;
@property (copy) JXHTTPBlock didStartBlock;
@property (copy) JXHTTPBlock didReceiveResponseBlock;
@property (copy) JXHTTPBlock didReceiveDataBlock;
@property (copy) JXHTTPBlock didSendDataBlock;
@property (copy) JXHTTPBlock didFinishLoadingBlock;
@property (copy) JXHTTPBlock didFailBlock;
@property (copy) JXHTTPCacheBlock willCacheResponseBlock;
@property (copy) JXHTTPRedirectBlock willSendRequestRedirectBlock;

// Initialization

+ (instancetype)withURLString:(NSString *)urlString;
+ (instancetype)withURLString:(NSString *)urlString queryParameters:(NSDictionary *)parameters;

@end
