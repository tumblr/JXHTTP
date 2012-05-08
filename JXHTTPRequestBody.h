#import "JXHTTPDelegate.h"

@protocol JXHTTPRequestBody <JXHTTPDelegate>
@required
- (NSInputStream *)httpInputStream;
- (NSString *)httpContentType;
- (long long)httpContentLength;
@end
