#import "JXHTTPDataBody.h"

@implementation JXHTTPDataBody

#pragma mark - Initialization

+ (id)withData:(NSData *)data andContentType:(NSString *)contentType
{
    id body = [[self alloc] init];
    [body setData:data];
    [body setHttpContentType:contentType];
    return body;
}

+ (id)withData:(NSData *)data
{
    return [self withData:data andContentType:nil];
}

+ (id)emptyBody
{
    return [self withData:nil andContentType:nil];
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
