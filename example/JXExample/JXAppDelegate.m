#import "JXAppDelegate.h"
#import "JXRemoteImageView.h"

@implementation JXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];

    JXRemoteImageView *remoteImageView = [[JXRemoteImageView alloc] initWithFrame:self.window.rootViewController.view.bounds];
    remoteImageView.imageURL = [[NSURL alloc] initWithString:@"http://upload.wikimedia.org/wikipedia/commons/6/62/Sts114_033.jpg"];
    
    [self.window.rootViewController.view addSubview:remoteImageView];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
