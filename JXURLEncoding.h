@interface JXURLEncoding : NSObject

// Encodes a string according to RFC 3986.
+ (NSString *)encodedString:(NSString *)string;

// Encodes a string according to RFC 3986, except using plus signs for spaces.
+ (NSString *)formEncodedString:(NSString *)string;

/*
Encodes a dictionary of strings according to RFC 3986 and joins them with
ampersand, with keys sorted by `localizedCaseInsensitiveCompare:`

Dictionary values must be either strings or dictionaries of more strings.
Subdictionaries will be encoded with bracket notation, i.e.
`subdictionary[key]=value&subdictionary[other_key]=another_value`
*/
+ (NSString *)encodedDictionary:(NSDictionary *)dictionary;

// Identical to `encodedDictionary` except using plus signs for spaces.
+ (NSString *)formEncodedDictionary:(NSDictionary *)dictionary;

@end
