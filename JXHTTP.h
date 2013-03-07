/*
Copyright (c) 2013 Justin Ouellette

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#pragma HC SVNT DRACONES

// Core
#import "JXOperation.h"
#import "JXURLConnectionOperation.h"
#import "JXHTTPOperation.h"
#import "JXHTTPOperationQueue.h"

// Protocol
#import "JXHTTPRequestBody.h"
#import "JXHTTPOperationDelegate.h"
#import "JXHTTPOperationQueueDelegate.h"

// Convenience
#import "JXURLEncoding.h"
#import "JXHTTPOperation+Convenience.h"

// Request Body
#import "JXHTTPDataBody.h"
#import "JXHTTPFileBody.h"
#import "JXHTTPFormEncodedBody.h"
#import "JXHTTPJSONBody.h"
#import "JXHTTPMultipartBody.h"

// Error Logging
#define JXError(error) if (error) { \
                        NSLog(@"%@ (%d) ERROR: %@", \
                        [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
                        __LINE__, [error localizedDescription]); }
