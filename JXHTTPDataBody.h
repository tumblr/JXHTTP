#import "JXHTTPRequestBody.h"

@interface JXHTTPDataBody : NSObject <JXHTTPRequestBody>

@property (nonatomic, retain) NSData *data;
@property (nonatomic, copy) NSString *httpContentType;

+ (id)emptyBody;
+ (id)withData:(NSData *)data;
+ (id)withData:(NSData *)data andContentType:(NSString *)contentType;

@end
