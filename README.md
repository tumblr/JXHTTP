# JXHTTP #

## Example ##

```objective-c
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "JXHTTP.h"

int main(int argc, char *argv[]) {
	__block JXHTTPOperation *op = [JXHTTPOperation withURLString:@"https://encrypted.google.com/"];
    op.completionBlock = ^{
        NSLog(@"%@", op.responseString);
    };
    
    [[JXHTTPOperationQueue sharedQueue] addOperation:op];
}
```
## Docs ##

To generate the HTML docs using [appledoc](http://gentlebytes.com/appledoc/):

```sh
cd jxhttp
appledoc \
	--project-name JXHTTP \
	--project-company "Justin Ouellette" \
	--company-id com.justinouellette \
	--no-create-docset \
	--create-html \
	--clean-output \
	--explicit-crossref \
	--no-repeat-first-par \
	--output ~/Desktop/jxhttp_docs \
	.
```

## License ##

MIT License, see [JXHTTP.h](https://github.com/jstn/JXHTTP/blob/master/JXHTTP.h)