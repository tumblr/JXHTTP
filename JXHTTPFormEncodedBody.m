#import "JXHTTPFormEncodedBody.h"
#import "JXURLEncoding.h"

@interface JXHTTPFormEncodedBody ()
@property (nonatomic, retain) NSMutableDictionary *dictionary;
- (id)initWithDictionary:(NSDictionary *)dict;
- (NSData *)requestData;
@end

@implementation JXHTTPFormEncodedBody

@synthesize dictionary;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [dictionary release];
    
    [super dealloc];
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    if ((self = [self init])) {
        self.dictionary = dict ? [NSMutableDictionary dictionaryWithDictionary:dict] : [NSMutableDictionary dictionary];
    }
    return self;
}

+ (id)withDictionary:(NSDictionary *)dictionary
{
    return [[[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (id)emptyBody
{
    return [self withDictionary:nil];
}

#pragma mark -
#pragma mark Private Methods

- (NSData *)requestData
{
    return [[JXURLEncoding formEncodedDictionary:self.dictionary] dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark -
#pragma mark <JXHTTPRequestBody>

- (NSInputStream *)httpInputStream
{
    return [NSInputStream inputStreamWithData:[self requestData]];
}

- (NSString *)httpContentType
{
    return @"application/x-www-form-urlencoded; charset=utf-8";
}

- (long long)httpContentLength
{
    return [[self requestData] length];
}

@end
