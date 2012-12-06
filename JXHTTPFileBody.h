#import "JXHTTPRequestBody.h"

@interface JXHTTPFileBody : NSObject <JXHTTPRequestBody>

@property (copy, nonatomic) NSString *filePath;
@property (copy, nonatomic) NSString *httpContentType;

+ (id)withFilePath:(NSString *)filePath;
+ (id)withFilePath:(NSString *)filePath contentType:(NSString *)contentType;

- (id)initWithFilePath:(NSString *)filePath contentType:(NSString *)contentType;

@end
