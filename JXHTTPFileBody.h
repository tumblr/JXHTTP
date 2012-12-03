#import "JXHTTPRequestBody.h"

@interface JXHTTPFileBody : NSObject <JXHTTPRequestBody>

@property (copy, nonatomic) NSString *filePath;
@property (copy, nonatomic) NSString *httpContentType;

+ (id)emptyBody;
+ (id)withFilePath:(NSString *)filePath;
+ (id)withFilePath:(NSString *)filePath andContentType:(NSString *)contentType;

@end
