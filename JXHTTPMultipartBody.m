#import "JXHTTPMultipartBody.h"

typedef enum {
    JXHTTPMultipartData,
    JXHTTPMultipartFile    
} JXHTTPMultipartPartType;

@interface JXHTTPMultipartPart : NSObject
@property (nonatomic, assign) JXHTTPMultipartPartType multipartType;
@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) NSData *preData;
@property (nonatomic, retain) NSData *contentData;
@property (nonatomic, retain) NSData *postData;
@end

@implementation JXHTTPMultipartPart

@synthesize multipartType, key, preData, contentData, postData;

- (void)dealloc
{
    [key release];
    [preData release];
    [contentData release];
    [postData release];
    
    [super dealloc];
}

+ (id)withMultipartType:(JXHTTPMultipartPartType)type
                    key:(NSString *)key
                   data:(NSData *)data
            contentType:(NSString *)contentTypeOrNil
               fileName:(NSString *)fileNameOrNil
               boundary:(NSString *)boundaryString
{
    JXHTTPMultipartPart *part = [[JXHTTPMultipartPart alloc] init];
    part.multipartType = type;    
    part.key = key;
    
    NSMutableString *preString = [NSMutableString stringWithFormat:@"%@\r\n", boundaryString];
    [preString appendFormat:@"Content-Disposition: form-data; name=\"%@\"", key];
    
    if ([fileNameOrNil length])
        [preString appendFormat:@"; filename=\"%@\"", fileNameOrNil];
    
    if ([contentTypeOrNil length]) {
        [preString appendFormat:@"\r\nContent-Type: %@", contentTypeOrNil];
    } else if(part.multipartType == JXHTTPMultipartFile) {
        [preString appendString:@"\r\nContent-Type: application/octet-stream"];
    }
    
    [preString appendString:@"\r\n\r\n"];
    
    part.preData = [preString dataUsingEncoding:NSUTF8StringEncoding];
    part.contentData = data;
    part.postData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];    

    return [part autorelease];
}

- (NSString *)filePath
{
    if (self.multipartType == JXHTTPMultipartFile)
        return [[[NSString alloc] initWithData:self.contentData encoding:NSUTF8StringEncoding] autorelease];
    
    return nil;
}

- (long long)dataLength
{
    long long length = 0;
    length += [self.preData length];
    length += [self contentLength];
    length += [self.postData length];
    return length;
}

- (long long)contentLength
{
    long long length = 0;
    
    if (self.multipartType == JXHTTPMultipartData) {
        length += [self.contentData length];
    } else if (self.multipartType == JXHTTPMultipartFile) {
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self filePath] error:&error];
        if (error != nil)
            NSLog(@"%@", error);
        
        NSNumber *fileSize = [attributes objectForKey:NSFileSize];
        if (fileSize)
            length += [fileSize longLongValue];
    }
    
    return length;
}

- (NSUInteger)loadMutableData:(NSMutableData *)mutableData withRange:(NSRange)searchRange
{
    NSUInteger dataOffset = 0;
    NSUInteger bytesAppended = 0;

    for (NSData *data in [NSArray arrayWithObjects:self.preData, self.contentData, self.postData, nil]) {
        NSUInteger dataLength = data == self.contentData ? [self contentLength] : [data length];
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        NSRange intersection = NSIntersectionRange(dataRange, searchRange);
        
        if (intersection.length > 0) {
            NSRange rangeInPart = NSMakeRange(intersection.location - dataOffset, intersection.length);
            NSData *dataToAppend = nil;
            
            if (data == self.preData || data == self.postData) {
                dataToAppend = [data subdataWithRange:rangeInPart];
            } else if (data == self.contentData) {
                if (self.multipartType == JXHTTPMultipartData) {
                    dataToAppend = [data subdataWithRange:rangeInPart];
                } else if (self.multipartType == JXHTTPMultipartFile) {
                    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:[self filePath]];
                    if (!fileHandle)
                        return bytesAppended;
                    
                    [fileHandle seekToFileOffset:rangeInPart.location];
                    dataToAppend = [fileHandle readDataOfLength:rangeInPart.length];
                    [fileHandle closeFile];
                }
            }
            
            if (dataToAppend) {
                [mutableData appendData:dataToAppend];
                bytesAppended += [dataToAppend length];
            }
        }

        dataOffset += dataLength;
    }

    return bytesAppended;
}

@end

#pragma mark -
#pragma mark JXHTTPMultiPartBody

@interface JXHTTPMultipartBody ()
@property (nonatomic, retain) NSMutableArray *partsArray;
@property (nonatomic, retain) NSString *boundaryString;
@property (nonatomic, retain) NSData *finalBoundaryData;
@property (nonatomic, retain) NSString *httpContentType;
@property (nonatomic, retain) NSInputStream *httpInputStream;
@property (nonatomic, retain) NSOutputStream *httpOutputStream;
@property (nonatomic, retain) NSMutableData *bodyDataBuffer;
@property (nonatomic, assign) NSUInteger streamBufferLength;
@property (nonatomic, assign) long long httpContentLength;
@property (nonatomic, assign) long long bytesWritten;
@end

@implementation JXHTTPMultipartBody

@synthesize partsArray, boundaryString, finalBoundaryData, httpContentType, httpInputStream, httpOutputStream,
            bodyDataBuffer, httpContentLength, bytesWritten, streamBufferLength;

#pragma mark -
#pragma mark Initialization

- (void)dealloc
{
    self.httpOutputStream.delegate = nil;    
    [self.httpOutputStream close];
    
    [partsArray release];    
    [boundaryString release];
    [finalBoundaryData release];
    [httpContentType release];
    [httpInputStream release];
    [httpOutputStream release];
    [bodyDataBuffer release];
    
    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid);
        NSString *dateString = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
        self.boundaryString = [NSString stringWithFormat:@"--JXHTTP-%@-%@", uuidString, dateString];
        CFRelease(uuidString);
        CFRelease(uuid);

        self.finalBoundaryData = [[NSString stringWithFormat:@"%@--\r\n", self.boundaryString] dataUsingEncoding:NSUTF8StringEncoding];
        self.httpContentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundaryString];
        self.partsArray = [NSMutableArray array];
        self.streamBufferLength = 0x10000; //64K

        [self recreateStreams];
    }
    return self;
}

+ (id)emptyBody
{
    return [[[self alloc] init] autorelease];
}

+ (id)withDictionary:(NSDictionary *)stringParameters
{
    id body = [[self alloc] init];
    
    for (NSString *key in [stringParameters allKeys]) {
        [body addString:[stringParameters objectForKey:key] forKey:key];
    }
    
    return [body autorelease];
}

#pragma mark -
#pragma mark <JXHTTPRequestBody>

- (long long)httpContentLength
{
    if (httpContentLength != NSURLResponseUnknownLength)
        return httpContentLength;

    long long newLength = 0;
    
    for (JXHTTPMultipartPart *part in self.partsArray) {
        newLength += [part dataLength];
    }
    
    if (newLength > 0)
        newLength += [self.finalBoundaryData length];
    
    self.httpContentLength = newLength;
    
    return httpContentLength;
}

#pragma mark -
#pragma mark <JXHTTPDelegate>

- (void)httpOperationWillNeedNewBodyStream:(JXHTTPOperation *)operation
{
    [self recreateStreams];
}

#pragma mark -
#pragma mark Private Methods

- (void)recreateStreams
{
    self.bodyDataBuffer = [NSMutableData dataWithCapacity:self.streamBufferLength];    
    self.httpContentLength = NSURLResponseUnknownLength;
    self.bytesWritten = 0;
    
    self.httpOutputStream.delegate = nil;
    [self.httpOutputStream close];
    
    self.httpInputStream = nil;
    self.httpOutputStream = nil;
    
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    
    CFStreamCreateBoundPair(kCFAllocatorDefault, &readStream, &writeStream, (CFIndex)self.streamBufferLength);
    
    if (readStream != NULL && writeStream != NULL) {
        self.httpInputStream = (NSInputStream *)readStream;
        self.httpOutputStream = (NSOutputStream *)writeStream;
        
        self.httpOutputStream.delegate = self;
        [self.httpOutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [self.httpOutputStream open];
    }
    
    if (readStream != NULL)
        CFRelease(readStream);
    
    if (writeStream != NULL)
        CFRelease(writeStream);
}

- (void)setPartWithType:(JXHTTPMultipartPartType)type forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil data:(NSData *)data
{
    NSMutableArray *removal = [NSMutableArray arrayWithCapacity:[self.partsArray count]];
    for (JXHTTPMultipartPart *part in self.partsArray) {
        if ([part.key isEqualToString:key])
            [removal addObject:part];
    }
    
    [self.partsArray removeObjectsInArray:removal];
    
    [self addPartWithType:type forKey:key contentType:contentTypeOrNil fileName:fileNameOrNil data:data];
}

- (void)addPartWithType:(JXHTTPMultipartPartType)type forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil data:(NSData *)data
{
    JXHTTPMultipartPart *part = [JXHTTPMultipartPart withMultipartType:type key:key data:data contentType:contentTypeOrNil fileName:fileNameOrNil boundary:self.boundaryString];
    [self.partsArray addObject:part];
    
    self.httpContentLength = NSURLResponseUnknownLength;
}

#pragma mark -
#pragma mark <NSStreamDelegate>

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    if (stream != self.httpOutputStream)
        return;
    
    if (eventCode == NSStreamEventErrorOccurred) {
        NSLog(@"%@ %@", stream.streamError, stream.streamError.userInfo);
        [self.httpOutputStream close];
        return;
    }
    
    if (eventCode != NSStreamEventHasSpaceAvailable)
        return;
    
    if (self.bytesWritten == self.httpContentLength) {
        [self.httpOutputStream close];
        return;
    }
    
    NSUInteger bytesRemaining = self.httpContentLength - self.bytesWritten;
    NSUInteger length = MIN(bytesRemaining, self.streamBufferLength);
    
    NSUInteger bytesLoaded = [self loadMutableData:self.bodyDataBuffer withRange:NSMakeRange(self.bytesWritten, length)];
    NSInteger bytesOutput = bytesLoaded ? [self.httpOutputStream write:[self.bodyDataBuffer bytes] maxLength:bytesLoaded] : 0;
    
    if (bytesOutput > 0) {
        self.bytesWritten += bytesOutput;
    } else {
        [self.httpOutputStream close];
    }
}

- (NSUInteger)loadMutableData:(NSMutableData *)data withRange:(NSRange)searchRange
{
    [data setLength:0];
    
    NSUInteger partOffset = 0;
    NSUInteger bytesLoaded = 0;
    
    for (JXHTTPMultipartPart *part in self.partsArray) {
        NSUInteger partLength = [part dataLength];
        NSRange partRange = NSMakeRange(partOffset, partLength);

        NSRange intersection = NSIntersectionRange(partRange, searchRange);
        if (intersection.length > 0) {
            NSRange rangeInPart = NSMakeRange(intersection.location - partOffset, intersection.length);
            bytesLoaded += [part loadMutableData:data withRange:rangeInPart];
        }
        
        partOffset += partLength;
    }

    NSRange finalRange = NSMakeRange(partOffset, [self.finalBoundaryData length]);
    NSRange intersection = NSIntersectionRange(finalRange, searchRange);
    if (intersection.length > 0) {
        NSRange range = NSMakeRange(intersection.location - partOffset, intersection.length);
        NSData *dataToAppend = [self.finalBoundaryData subdataWithRange:range];
        if (dataToAppend) {
            [data appendData:dataToAppend];
            bytesLoaded += [dataToAppend length];
        }
    }
    
    return bytesLoaded;
}

#pragma mark -
#pragma mark Public Methods

- (void)addString:(NSString *)string forKey:(NSString *)key
{
    [self addData:[string dataUsingEncoding:NSUTF8StringEncoding] forKey:key contentType:nil fileName:nil];
}

- (void)setString:(NSString *)string forKey:(NSString *)key
{
    [self setData:[string dataUsingEncoding:NSUTF8StringEncoding] forKey:key contentType:nil fileName:nil];
}

- (void)addData:(NSData *)data forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil
{
    [self addPartWithType:JXHTTPMultipartData forKey:key contentType:contentTypeOrNil fileName:fileNameOrNil data:data];
}

- (void)setData:(NSData *)data forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil
{
    [self setPartWithType:JXHTTPMultipartData forKey:key contentType:contentTypeOrNil fileName:fileNameOrNil data:data];
}

- (void)addFile:(NSString *)filePath forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil
{
    [self addPartWithType:JXHTTPMultipartFile forKey:key contentType:contentTypeOrNil fileName:fileNameOrNil data:[filePath dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)setFile:(NSString *)filePath forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil
{
    [self setPartWithType:JXHTTPMultipartFile forKey:key contentType:contentTypeOrNil fileName:fileNameOrNil data:[filePath dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
