#import "JXHTTPOperationDelegate.h"

@protocol JXHTTPRequestBody <JXHTTPOperationDelegate>
@required
- (NSInputStream *)httpInputStream;
- (NSString *)httpContentType;
- (long long)httpContentLength;
@end
