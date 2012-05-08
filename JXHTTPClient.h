#import "JXHTTPRequestBody.h"

@class JXHTTPOperation;

typedef void (^JXHTTPOperationBlock)(JXHTTPOperation *operation);

@interface JXHTTPClient : NSObject

@property (retain) NSOperationQueue *connectionQueue;

+ (id)sharedClient;

- (void)performOperationSynchronously:(JXHTTPOperation *)httpOperation;

@end
