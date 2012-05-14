#import "JXHTTPRequestBody.h"

@interface JXHTTPFormEncodedBody : NSObject <JXHTTPRequestBody>

@property (nonatomic, retain, readonly) NSMutableDictionary *dictionary;

- (id)initWithDictionary:(NSDictionary *)dictionary;
+ (id)withDictionary:(NSDictionary *)dictionary;

@end
