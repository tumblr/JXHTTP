/**
 `JXURLEncoding` is an abstract class providing methods for encoding strings according
 to [RFC 3986]( http://www.ietf.org/rfc/rfc3986.txt ) (aka "percent escaping").
 
 As with the rest of `JXHTTP`, input and output strings should always be UTF-8.
 */

@interface JXURLEncoding : NSObject

/**
 Encodes a string according to RFC 3986.

 @param string A string to encode.
 @returns An autoreleased string.
 */
+ (NSString *)encodedString:(NSString *)string;

/**
 Encodes a string according to RFC 3986, except with "+" replacing spaces.
 Commonly used by web browsers to submit forms.

 @param string A string to encode.
 @returns An autoreleased string.
 */
+ (NSString *)formEncodedString:(NSString *)string;

/**
 Encodes a dictionary according to RFC 3986, with keys sorted alphabetically and flattened
 into a query string. Dictionary values must be a either string or a collection object
 that contains strings or nested collections of strings (i.e., `NSArray` or `NSDictionary`).
 
 ### Example ###
 
    NSDictionary *params = @{
        @"make": @"BMW",
        @"model": @"335i",
        @"options": @[ @"heated seats", @"navigation system" ]
    };
 
    // make=BMW&model=335i&options[0]=heated%20seats&options[1]=navigation%20system

 @param dictionary A dictionary to encode.
 @returns An autoreleased string.
 */
+ (NSString *)encodedDictionary:(NSDictionary *)dictionary;

/**
 Encodes a dictionary according to RFC 3986, with keys sorted alphabetically and flattened
 into a query string. Dictionary values must be a either string or a collection object
 that contains strings or nested collections of strings (i.e., `NSArray` or `NSDictionary`).
 Identical to <encodedDictionary:> except with "+" replacing spaces.

 ### Example ###

     NSDictionary *params = @{
         @"make": @"BMW",
         @"model": @"335i",
         @"options": @[ @"heated seats", @"navigation system" ]
     };

     // make=BMW&model=335i&options[0]=heated+seats&options[1]=navigation+system

 @param dictionary A dictionary to encode.
 @returns An autoreleased string.
 */
+ (NSString *)formEncodedDictionary:(NSDictionary *)dictionary;

@end
