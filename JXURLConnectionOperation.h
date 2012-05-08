#import "JXOperation.h"

@interface JXURLConnectionOperation : JXOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (retain, readonly) NSMutableURLRequest *request;
@property (retain, readonly) NSURLResponse *response;
@property (retain, readonly) NSError *error;
@property (assign, readonly) long long bytesReceived;
@property (assign, readonly) long long bytesSent;
@property (retain) NSOutputStream *outputStream;

- (id)initWithURL:(NSURL *)url;

@end
