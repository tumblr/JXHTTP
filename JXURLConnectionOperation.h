#import "JXOperation.h"

@interface JXURLConnectionOperation : JXOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (strong, readonly) NSMutableURLRequest *request;
@property (strong, readonly) NSURLResponse *response;
@property (strong, readonly) NSError *connectionError;

@property (assign, readonly) long long bytesDownloaded;
@property (assign, readonly) long long bytesUploaded;

@property (strong) NSOutputStream *outputStream;

+ (NSThread *)sharedThread;

- (instancetype)initWithURL:(NSURL *)url;

@end
