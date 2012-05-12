#import "JXHTTPRequestBody.h"

@class JXHTTPOperation;
@class JXHTTPOperationQueue;

typedef void (^JXHTTPOperationBlock)(JXHTTPOperation *operation);

@interface JXHTTPClient : NSObject

@property (nonatomic, retain) JXHTTPOperationQueue *operationQueue;

+ (id)sharedClient;

- (void)performOperationSynchronously:(JXHTTPOperation *)httpOperation;

@end
