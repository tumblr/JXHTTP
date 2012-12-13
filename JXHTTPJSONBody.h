#import "JXHTTPRequestBody.h"

@interface JXHTTPJSONBody : NSObject <JXHTTPRequestBody>

+ (instancetype)withData:(NSData *)data;
+ (instancetype)withString:(NSString *)string;
+ (instancetype)withJSONObject:(id)dictionaryOrArray;

- (instancetype)initWithData:(NSData *)data;

@end
