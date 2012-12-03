#import "JXHTTPJSONBody.h"

@interface JXHTTPJSONBody ()
@property (strong, nonatomic) NSData *requestData;
@end

@implementation JXHTTPJSONBody

#pragma mark - Initialization

+ (id)withData:(NSData *)data
{
    id body = [[self alloc] init];
    [body setRequestData:data];
    return body;
}

+ (id)withString:(NSString *)string
{
    return [self withData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (id)withJSONObject:(id)dictionaryOrArray
{
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionaryOrArray options:0 error:&error];
    if (error)
        NSLog(@"%@", error);
        
    return [self withData:data];
}

#pragma mark - <JXHTTPRequestBody>

- (NSInputStream *)httpInputStream
{
    return [[NSInputStream alloc] initWithData:self.requestData];
}

- (NSString *)httpContentType
{
    return @"application/json; charset=utf-8";
}

- (long long)httpContentLength
{
    return [self.requestData length];
}

#pragma mark - <JXHTTPOperationDelegate>

- (void)httpOperationDidFinishLoading:(JXHTTPOperation *)operation
{
    self.requestData = nil;
}

@end
