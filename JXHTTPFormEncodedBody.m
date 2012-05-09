#import "JXHTTPFormEncodedBody.h"
#import "JXURLEncoding.h"

@interface JXHTTPFormEncodedBody ()
@property (nonatomic, retain) NSData *requestData;
@end

@implementation JXHTTPFormEncodedBody

@synthesize requestData;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [requestData release];
    
    [super dealloc];
}

+ (id)withDictionary:(NSDictionary *)dictionary
{
    id body = [[self alloc] init];
    NSString *requestString = [JXURLEncoding formEncodedDictionary:dictionary]; 
    [body setRequestData:[requestString dataUsingEncoding:NSUTF8StringEncoding]];
    return [body autorelease];
}

#pragma mark -
#pragma mark <JXHTTPRequestBody>

- (NSInputStream *)httpInputStream
{
    return [NSInputStream inputStreamWithData:self.requestData];
}

- (NSString *)httpContentType
{
    return @"application/x-www-form-urlencoded";
}

- (long long)httpContentLength
{
    return [self.requestData length];
}

#pragma mark -
#pragma mark <JXHTTPDelegate>

- (void)httpOperationDidFinish:(JXHTTPOperation *)operation
{
    self.requestData = nil;
}

@end
