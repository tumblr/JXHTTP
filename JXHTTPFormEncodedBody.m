#import "JXHTTPFormEncodedBody.h"
#import "JXURLEncoding.h"

@interface JXHTTPFormEncodedBody ()
@property (strong, nonatomic) NSMutableDictionary *dictionary;
@end

@implementation JXHTTPFormEncodedBody

#pragma mark - Initialization

- (id)initWithDictionary:(NSDictionary *)dict
{
    if (self = [self init]) {
        self.dictionary = dict ? [[NSMutableDictionary alloc] initWithDictionary:dict] : [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (id)withDictionary:(NSDictionary *)dictionary
{
    return [[self alloc] initWithDictionary:dictionary];
}

+ (id)emptyBody
{
    return [self withDictionary:nil];
}

#pragma mark - Private Methods

- (NSData *)requestData
{
    return [[JXURLEncoding formEncodedDictionary:self.dictionary] dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark - <JXHTTPRequestBody>

- (NSInputStream *)httpInputStream
{
    return [[NSInputStream alloc] initWithData:[self requestData]];
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
