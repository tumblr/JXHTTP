#import "JXHTTPRequestBody.h"

@interface JXHTTPFileBody : NSObject <JXHTTPRequestBody>

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *httpContentType;

+ (id)emptyBody;
+ (id)withFilePath:(NSString *)filePath;
+ (id)withFilePath:(NSString *)filePath andContentType:(NSString *)contentType;

@end
