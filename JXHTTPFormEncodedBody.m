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

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if ((self = [self init])) {
        NSString *requestString = [JXURLEncoding formEncodedDictionary:dictionary];        
        self.requestData = [requestString dataUsingEncoding:NSUTF8StringEncoding];
    }
    return self;
}

+ (id)withDictionary:(NSDictionary *)dictionary
{
    return [[[self alloc] initWithDictionary:dictionary] autorelease];
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
