#import "JXHTTPRequestBody.h"

static NSString * const JXHTTPRequestBodyDefaultContentType = @"application/octet-stream";

@implementation JXHTTPRequestBody

@synthesize inputStream, contentType, expectedContentLength;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [inputStream release];
    [contentType release];
    
    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        self.expectedContentLength = 0;
        self.contentType = JXHTTPRequestBodyDefaultContentType;
        self.inputStream = [NSInputStream inputStreamWithData:[NSData data]];
    }
    return self;
}

- (id)initWithData:(NSData *)data contentType:(NSString *)type
{
    if ((self = [self init])) {
        self.inputStream = [NSInputStream inputStreamWithData:data];
        self.expectedContentLength = [data length];
        self.contentType = type;        
    }
    return self;
}

- (id)initWithFile:(NSString *)filePath contentType:(NSString *)type
{
    if ((self = [self init])) {
        self.contentType = type;
        self.inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
        
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
        if (error != nil)
            NSLog(@"%@", error);

        NSNumber *fileSize = [attributes objectForKey:NSFileSize];
        self.expectedContentLength = [fileSize longLongValue];
    }
    return self;
}

+ (id)withData:(NSData *)data contentType:(NSString *)contentType
{
    return [[[self alloc] initWithData:data contentType:contentType] autorelease];
}

+ (id)withFile:(NSString *)filePath contentType:(NSString *)contentType
{
    return [[[self alloc] withFile:filePath contentType:contentType] autorelease];
}

+ (id)withData:(NSData *)data;
{
    return [self withData:data contentType:JXHTTPRequestBodyDefaultContentType];
}

+ (id)withFile:(NSString *)filePath
{
    return [self withFile:filePath contentType:JXHTTPRequestBodyDefaultContentType];
}

@end