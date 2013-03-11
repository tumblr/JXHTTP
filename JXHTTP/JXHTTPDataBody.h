#import "JXHTTPRequestBody.h"

@interface JXHTTPDataBody : NSObject <JXHTTPRequestBody>

@property (strong, nonatomic) NSData *data;
@property (copy, nonatomic) NSString *httpContentType;

+ (instancetype)withData:(NSData *)data;
+ (instancetype)withData:(NSData *)data contentType:(NSString *)contentType;

- (instancetype)initWithData:(NSData *)data contentType:(NSString *)contentType;

@end
