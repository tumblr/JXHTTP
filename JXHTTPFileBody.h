#import "JXHTTPRequestBody.h"

@interface JXHTTPFileBody : NSObject <JXHTTPRequestBody>

@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSString *httpContentType;

+ (id)withFilePath:(NSString *)filePath;
+ (id)withFilePath:(NSString *)filePath andContentType:(NSString *)contentType;

@end
