#import "JXHTTPJSONBody.h"

@interface JXHTTPJSONBody ()
@property (nonatomic, retain) NSData *requestData;
@end

@implementation JXHTTPJSONBody

@synthesize requestData;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [requestData release];
    
    [super dealloc];
}

+ (id)withData:(NSData *)data
{
    id body = [[self alloc] init];
    [body setRequestData:data];
    return [body autorelease];
}

+ (id)withString:(NSString *)string
{
    return [self withData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (id)withJSONObject:(id)dictionaryOrArray
{
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionaryOrArray options:0 error:&error];
    if (error)
        NSLog(@"%@", error);
        
    return [self withData:data];
}

#pragma mark -
#pragma mark <JXHTTPRequestBody>

- (NSInputStream *)httpInputStream
{
    return [NSInputStream inputStreamWithData:self.requestData];
}

- (NSString *)httpContentType
{
    return @"application/json; charset=utf-8";
}

- (long long)httpContentLength
{
    return [self.requestData length];
}

#pragma mark -
#pragma mark <JXHTTPOperationDelegate>

- (void)httpOperationDidFinish:(JXHTTPOperation *)operation
{
    self.requestData = nil;
}

@end
