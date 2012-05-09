#import "JXHTTPRequestBody.h"

@interface JXHTTPJSONBody : NSObject <JXHTTPRequestBody>

+ (id)withData:(NSData *)data;
+ (id)withString:(NSString *)string;
+ (id)withJSONObject:(id)dictionaryOrArray;

@end
