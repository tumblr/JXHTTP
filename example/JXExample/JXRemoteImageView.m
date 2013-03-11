#import "JXRemoteImageView.h"
#import "JXHTTP.h"

@implementation JXRemoteImageView

- (instancetype)initWithURL:(NSURL *)imageURL
{
    if (self = [self initWithFrame:CGRectZero]) {
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;

        JXHTTPOperation *op = [[JXHTTPOperation alloc] initWithURL:imageURL];

        op.didFinishLoadingBlock = ^(JXHTTPOperation *op) {
            UIImage *image = [[UIImage alloc] initWithData:[op responseData]];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = image;
            });
        };

        op.didFailBlock = ^(JXHTTPOperation *op) {
            NSLog(@"image load failed! error: %@", op.error);
        };

        [[JXHTTPOperationQueue sharedQueue] addOperation:op];
    }
    return self;
}

@end
