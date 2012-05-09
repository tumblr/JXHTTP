#import "JXHTTPRequestBody.h"

@interface JXHTTPMultipartBody : NSObject <NSStreamDelegate, JXHTTPRequestBody>

+ (id)emptyBody;
+ (id)withDictionary:(NSDictionary *)stringParameters;

- (void)addString:(NSString *)string forKey:(NSString *)key;
- (void)setString:(NSString *)string forKey:(NSString *)key;

- (void)addData:(NSData *)data forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil;
- (void)setData:(NSData *)data forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil;

- (void)addFile:(NSString *)filePath forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil;
- (void)setFile:(NSString *)filePath forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil;

@end
