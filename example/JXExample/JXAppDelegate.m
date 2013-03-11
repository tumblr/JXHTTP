#import "JXAppDelegate.h"
#import "JXRemoteImageView.h"

@implementation JXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    [self.window makeKeyAndVisible];

    NSURL *imageURL = [[NSURL alloc] initWithString:@"http://upload.wikimedia.org/wikipedia/en/2/24/Lenna.png"];
    JXRemoteImageView *remoteImageView = [[JXRemoteImageView alloc] initWithURL:imageURL];
    [self.window.rootViewController.view addSubview:remoteImageView];
    remoteImageView.frame = remoteImageView.superview.bounds;

    return YES;
}

@end
