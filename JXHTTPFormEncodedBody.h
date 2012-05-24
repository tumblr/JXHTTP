#import "JXHTTPRequestBody.h"

@interface JXHTTPFormEncodedBody : NSObject <JXHTTPRequestBody>

@property (nonatomic, retain, readonly) NSMutableDictionary *dictionary;

+ (id)emptyBody;
+ (id)withDictionary:(NSDictionary *)dictionary;

@end
