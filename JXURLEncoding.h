@interface JXURLEncoding : NSObject

+ (NSString *)encodedString:(NSString *)string;
+ (NSString *)formEncodedString:(NSString *)string;

+ (NSString *)encodedDictionary:(NSDictionary *)dictionary;
+ (NSString *)formEncodedDictionary:(NSDictionary *)dictionary;

@end
