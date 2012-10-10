#import "JXURLEncoding.h"

@implementation JXURLEncoding

#pragma mark -
#pragma mark NSString Encoding

+ (NSString *)encodedString:(NSString *)string
{
    if (![string length])
        return nil;
    
    static CFStringRef const charsToEscape = CFSTR(":/?#[]@!$&'()*+,;="); // RFC 3986 reserved
    static CFStringRef const charsToLeave = CFSTR("-._~"); // RFC 3986 unreserved
    CFStringRef escapedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, charsToLeave, charsToEscape, kCFStringEncodingUTF8);
    NSString *resultString = [NSString stringWithString:(NSString *)escapedString];
    CFRelease(escapedString);
    return resultString;
}

+ (NSString *)formEncodedString:(NSString *)string
{
    return [[self encodedString:string] stringByReplacingOccurrencesOfString:@"%20" withString:@"+"];
}

#pragma mark -
#pragma mark NSDictionary Encoding

+ (NSString *)encodedDictionary:(NSDictionary *)dictionary
{
    if (![dictionary count])
        return nil;
    
    NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:[dictionary count]];
    
    NSArray *sortedKeys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for (NSString *key in sortedKeys) {
        [self encodeObject:[dictionary objectForKey:key] withKey:key andSubKey:nil intoArray:arguments];
    }
    
    return [arguments componentsJoinedByString:@"&"];
}

+ (NSString *)formEncodedDictionary:(NSDictionary *)dictionary
{
    return [[self encodedDictionary:dictionary] stringByReplacingOccurrencesOfString:@"%20" withString:@"+"];
}

#pragma mark -
#pragma mark Private Methods

+ (void)encodeObject:(id)object withKey:(NSString *)key andSubKey:(NSString *)subKey intoArray:(NSMutableArray *)array
{
    NSString *objectKey = nil;
    
    if (subKey) {
        objectKey = [NSString stringWithFormat:@"%@[%@]", [self encodedString:key], [self encodedString:subKey]];
    } else {
        objectKey = [self encodedString:key];
    }
    
    if ([object respondsToSelector:@selector(objectForKey:)]) {
        NSArray *sortedKeys = [[object allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        for (NSString *insideKey in sortedKeys) {
            [self encodeObject:[object objectForKey:insideKey] withKey:objectKey andSubKey:insideKey intoArray:array];
        }
    } else if ([object isKindOfClass:[NSArray class]]) {
        for (NSString *arrayObject in (NSArray *)object) {
            NSString *arrayKey = [NSString stringWithFormat:@"%@[]", objectKey];
            [self encodeObject:arrayObject withKey:arrayKey andSubKey:nil intoArray:array];
        }
    } else if ([object isKindOfClass:[NSNumber class]]) {
        [array addObject:[NSString stringWithFormat:@"%@=%@", objectKey, [object stringValue]]];
    } else {
        NSString *encodedString = [self encodedString:object];
        [array addObject:[NSString stringWithFormat:@"%@=%@", objectKey, encodedString]];
    }
}

@end
