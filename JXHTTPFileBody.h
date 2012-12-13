#import "JXHTTPRequestBody.h"

@interface JXHTTPFileBody : NSObject <JXHTTPRequestBody>

@property (copy, nonatomic) NSString *filePath;
@property (copy, nonatomic) NSString *httpContentType;

+ (instancetype)withFilePath:(NSString *)filePath;
+ (instancetype)withFilePath:(NSString *)filePath contentType:(NSString *)contentType;

- (instancetype)initWithFilePath:(NSString *)filePath contentType:(NSString *)contentType;

@end
