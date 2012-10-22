#import "JXURLConnectionOperation.h"
#import "JXHTTPOperationDelegate.h"
#import "JXHTTPRequestBody.h"

typedef void (^JXHTTPBlock)(JXHTTPOperation *operation);

@interface JXHTTPOperation : JXURLConnectionOperation

/// @name Core

@property (assign) NSObject <JXHTTPOperationDelegate> *delegate;
@property (retain) NSObject <JXHTTPRequestBody> *requestBody;
@property (retain, readonly) NSString *uniqueString;
@property (assign) BOOL performsDelegateMethodsOnMainThread;
@property (nonatomic, copy) NSString *responseDataFilePath;
@property (retain) id userObject;

/// @name Security

@property (retain, readonly) NSURLAuthenticationChallenge *authenticationChallenge;
@property (retain) NSURLCredential *credential;
@property (assign) BOOL useCredentialStorage;
@property (assign) BOOL trustAllHosts;
@property (copy) NSArray *trustedHosts;
@property (copy) NSString *username;
@property (copy) NSString *password;

/// @name Progress

@property (retain, readonly) NSNumber *downloadProgress;
@property (retain, readonly) NSNumber *uploadProgress;
@property (assign) BOOL updatesNetworkActivityIndicator;

/// @name Blocks

@property (assign) BOOL performsBlocksOnMainThread;
@property (copy) JXHTTPBlock willStartBlock;
@property (copy) JXHTTPBlock willNeedNewBodyStreamBlock;
@property (copy) JXHTTPBlock willSendRequestForAuthenticationChallengeBlock;
@property (copy) JXHTTPBlock didReceiveResponseBlock;
@property (copy) JXHTTPBlock didReceiveDataBlock;
@property (copy) JXHTTPBlock didSendDataBlock;
@property (copy) JXHTTPBlock didFinishLoadingBlock;
@property (copy) JXHTTPBlock didFailBlock;

+ (NSOperationQueue *)serialBlockQueue;

/// @name Initialization

+ (id)withURLString:(NSString *)urlString;
+ (id)withURLString:(NSString *)urlString queryParameters:(NSDictionary *)parameters;

@end
