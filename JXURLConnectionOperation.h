#import "JXOperation.h"

/**
 Manages an `NSURLConnection` and tracks the number of bytes sent and received.
 Response data is written to an `NSOutputStream` that can be provided by the
 developer or output to memory by default. Both the connection and the stream
 are scheduled on the current thread's runloop for `NSRunLoopCommonModes`.
 */

@interface JXURLConnectionOperation : JXOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

/// @name URL Connection

/**
 The request object that will be used to create the `NSURLConnection` once the
 operation starts.
 */
@property (retain, readonly) NSMutableURLRequest *request;

/**
 The reponse object of the `NSURLConnection` once it has completed.
 */
@property (retain, readonly) NSURLResponse *response;

/**
 The error, if one exists, reported by the `NSURLConnection` upon failure.
 */
@property (retain, readonly) NSError *error;

/**
 The output stream to which the `NSURLConnection` will write its response data.
 Must be a new, unopened stream. Defaults to a stream with output to memory.
 */
@property (retain) NSOutputStream *outputStream;

/// @name Tracking Progress

/**
 The number of bytes written to the output stream (not necessarily the number
 of bytes downloaded over the wire, e.g. if the stream runs out of available
 space before the connection is complete).
 */
@property (assign, readonly) long long bytesDownloaded;

/**
 The number of bytes uploaded.
 */
@property (assign, readonly) long long bytesUploaded;

/**
 Creates a new `JXURLConnectionOperation` with a specified URL.

 @param url The URL to request.
 @returns An autoreleased operation.
 */
- (id)initWithURL:(NSURL *)url;

@end
