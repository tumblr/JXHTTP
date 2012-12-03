#import "JXHTTPRequestBody.h"

@interface JXHTTPDataBody : NSObject <JXHTTPRequestBody>

@property (strong, nonatomic) NSData *data;
@property (copy, nonatomic) NSString *httpContentType;

+ (id)emptyBody;
+ (id)withData:(NSData *)data;
+ (id)withData:(NSData *)data andContentType:(NSString *)contentType;

@end
