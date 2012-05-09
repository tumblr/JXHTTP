#import "JXHTTPRequestBody.h"

@interface JXHTTPFormEncodedBody : NSObject <JXHTTPRequestBody>

+ (id)withDictionary:(NSDictionary *)dictionary;

@end
