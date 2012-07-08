/**
 Provides string escaping in compliance with RFC 3986,
 [URI Generic Syntax](http://www.ietf.org/rfc/rfc3986.txt).
 
 Why `CFURLCreateStringByAddingPercentEscapes` doesn't do it properly in the
 first place is a mystery for the ages.
 */

@interface JXURLEncoding : NSObject

/**
 Encodes a string according to RFC 3986.
 
 @param string The string to encode.
 @returns An encoded string.
 */
+ (NSString *)encodedString:(NSString *)string;

/**
 Encodes a string according to RFC 3986, except for spaces which are encoded as
 `+` instead of `%20`. This style is typically used by browsers for form data
 and some web servers require it.
 
 @param string The string to encode.
 @returns An encoded string using `+` for spaces.
 */
+ (NSString *)formEncodedString:(NSString *)string;

/**
 Encodes a dictionary of strings according to RFC 3986 and joins them with
 ampersand, with keys sorted by `localizedCaseInsensitiveCompare:`
 
 Dictionary values must be either strings or dictionaries of more strings.
 Subdictionaries will be encoded with bracket notation, i.e.
 `subdictionary[key]=value&subdictionary[other_key]=another_value`
 
 @param dictionary The dictionary of strings to encode.
 @returns An encoded string with key-value pairs joined by `&`.
 */
+ (NSString *)encodedDictionary:(NSDictionary *)dictionary;

/**
 Identical to <encodedDictionary:> except using plus signs for spaces.
 
 @param dictionary The dictionary of strings to encode.
 @returns An encoded string with key-value pairs joined by `&` and using `+`
 for spaces.
 */
+ (NSString *)formEncodedDictionary:(NSDictionary *)dictionary;

@end
