#import "JXHTTPRequestBody.h"

@interface JXHTTPFormEncodedBody : NSObject <JXHTTPRequestBody>

- (id)initWithDictionary:(NSDictionary *)dictionary;
+ (id)withDictionary:(NSDictionary *)dictionary;

@end
