#import "JXHTTPDataBody.h"

@implementation JXHTTPDataBody

#pragma mark - Initialization

- (id)initWithData:(NSData *)data contentType:(NSString *)contentType
{
    if (self = [super init]) {
        self.data = data;
        self.httpContentType = contentType;
    }
    return self;
}

+ (id)withData:(NSData *)data contentType:(NSString *)contentType
{
    return [[self alloc] initWithData:data contentType:contentType];
}

+ (id)withData:(NSData *)data
{
    return [self withData:data contentType:nil];
}

#pragma mark - <JXHTTPRequestBody>

- (NSInputStream *)httpInputStream
{
    return [[NSInputStream alloc] initWithData:self.data];
}

- (long long)httpContentLength
{
    return [self.data length];
}

@end
