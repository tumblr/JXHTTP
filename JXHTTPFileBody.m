#import "JXHTTPFileBody.h"

@implementation JXHTTPFileBody

#pragma mark - Initialization

- (id)initWithFilePath:(NSString *)filePath contentType:(NSString *)contentType
{
    if (self = [super init]) {
        self.filePath = filePath;
        self.httpContentType = contentType;
    }
    return self;
}

+ (id)withFilePath:(NSString *)filePath contentType:(NSString *)contentType
{
    return [[self alloc] initWithFilePath:filePath contentType:contentType];
}

+ (id)withFilePath:(NSString *)filePath
{
    return [self withFilePath:filePath contentType:nil];
}

#pragma mark - <JXHTTPRequestBody>

- (NSInputStream *)httpInputStream
{
    return [[NSInputStream alloc] initWithFileAtPath:self.filePath];
}

- (long long)httpContentLength
{
    if (![self.filePath length])
        return NSURLResponseUnknownLength;

    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:&error];
    if (error != nil)
        NSLog(@"%@", error);
    
    NSNumber *fileSize = [attributes objectForKey:NSFileSize];
    if (fileSize)
        return [fileSize longLongValue];

    return NSURLResponseUnknownLength;
}

@end
