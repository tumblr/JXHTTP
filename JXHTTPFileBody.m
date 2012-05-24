#import "JXHTTPFileBody.h"

@implementation JXHTTPFileBody

@synthesize filePath, httpContentType;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    [filePath release];
    
    [super dealloc];
}

+ (id)emptyBody
{
    return [self withFilePath:nil andContentType:nil];
}

+ (id)withFilePath:(NSString *)filePath
{
    return [self withFilePath:filePath andContentType:nil];
}

+ (id)withFilePath:(NSString *)filePath andContentType:(NSString *)contentType
{
    id body = [[self alloc] init];
    [body setFilePath:filePath];
    [body setHttpContentType:contentType];
    return [body autorelease];
}

#pragma mark -
#pragma mark <JXHTTPRequestBody>

- (NSInputStream *)httpInputStream
{
    return [NSInputStream inputStreamWithFileAtPath:self.filePath];
}

- (long long)httpContentLength
{
    if (![self.filePath length])
        return NSURLResponseUnknownLength;

    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:&error];
    if (error != nil)
        NSLog(@"%@", error);
    
    NSNumber *fileSize = [attributes objectForKey:NSFileSize];
    if (fileSize)
        return [fileSize longLongValue];

    return NSURLResponseUnknownLength;
}

@end
