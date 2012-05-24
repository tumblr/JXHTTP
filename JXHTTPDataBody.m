#import "JXHTTPDataBody.h"

@implementation JXHTTPDataBody

@synthesize data, httpContentType;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [data release];

    [super dealloc];
}

+ (id)withData:(NSData *)data andContentType:(NSString *)contentType
{
    id body = [[self alloc] init];
    [body setData:data];
    [body setHttpContentType:contentType];
    return [body autorelease];
}

+ (id)withData:(NSData *)data
{
    return [self withData:data andContentType:nil];
}

+ (id)emptyBody
{
    return [self withData:nil andContentType:nil];
}

#pragma mark -
#pragma mark <JXHTTPRequestBody>

- (NSInputStream *)httpInputStream
{
    return [NSInputStream inputStreamWithData:self.data];
}

- (long long)httpContentLength
{
    return [self.data length];
}

@end
