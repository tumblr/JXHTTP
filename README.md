# JXHTTP #

## You Know, For Networking ##

JXHTTP uses ARC and GCD, and thus requires iOS 5.0 or OS X 10.7 (or newer). Better docs coming soon.

## Examples ##

`#import "JXHTTP.h"` somewhere convenient. We assume you've already imported `Foundation.h` somewhere.

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

## License ##

MIT License, see [JXHTTP.h](https://github.com/jstn/JXHTTP/blob/master/JXHTTP.h)
