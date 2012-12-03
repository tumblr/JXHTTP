#import "JXHTTPRequestBody.h"

@interface JXHTTPFormEncodedBody : NSObject <JXHTTPRequestBody>

@property (strong, readonly, nonatomic) NSMutableDictionary *dictionary;

+ (id)emptyBody;
+ (id)withDictionary:(NSDictionary *)dictionary;

@end
