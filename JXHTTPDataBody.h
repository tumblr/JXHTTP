#import "JXHTTPRequestBody.h"

@interface JXHTTPDataBody : NSObject <JXHTTPRequestBody>

@property (strong, nonatomic) NSData *data;
@property (copy, nonatomic) NSString *httpContentType;

+ (id)withData:(NSData *)data;
+ (id)withData:(NSData *)data contentType:(NSString *)contentType;

- (id)initWithData:(NSData *)data contentType:(NSString *)contentType;

@end
