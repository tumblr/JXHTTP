# JXHTTP #

JXHTTP uses ARC and GCD, and thus requires iOS 5.0 or OS X 10.7 (or newer).

## Examples ##

`#import "JXHTTP.h"` somewhere convenient.

### Asynchronous ###

```objective-c
JXHTTPOperation *op = [JXHTTPOperation withURLString:@"https://encrypted.google.com/"];
op.didFinishLoadingBlock = ^(JXHTTPOperation *op) {
    NSLog(@"%@", op.responseString);
};

[[JXHTTPOperationQueue sharedQueue] addOperation:op];
```

### Synchronous ###

```objective-c
JXHTTPOperation *op = [JXHTTPOperation withURLString:@"https://encrypted.google.com/"];
[op startAndWaitUntilFinished];

NSLog(@"%@", op.responseString);
```
