# JXHTTP #

## iOS networking framework ##

See [jxhttp.justinouellette.com](http://jxhttp.justinouellette.com) for more details.

## Examples ##

`#import "JXHTTP.h"` or you're gonna have a bad time.

### Asynchronous ###

```objective-c
__block JXHTTPOperation *op = [JXHTTPOperation withURLString:@"https://encrypted.google.com/"];
op.completionBlock = ^{
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

## Documentation ##

Generate HTML docs with [appledoc](http://gentlebytes.com/appledoc/) from the project root:

```sh
appledoc \
	--project-name JXHTTP \
	--project-company "Justin Ouellette" \
	--company-id com.justinouellette \
	--no-create-docset \
	--create-html \
	--clean-output \
	--explicit-crossref \
	--no-repeat-first-par \
	--output "~/Desktop/JXHTTP docs" \
	.
```

## License ##

MIT License, see [JXHTTP.h](https://github.com/jstn/JXHTTP/blob/master/JXHTTP.h)