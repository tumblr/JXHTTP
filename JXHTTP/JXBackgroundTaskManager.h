//
//  JXBackgroundTaskManager.h
//  JXExample
//
//  Created by Bryan Irace on 4/24/15.
//  Copyright (c) 2015 JXHTTP. All rights reserved.
//

@protocol JXBackgroundTaskManager <NSObject>

- (UIBackgroundTaskIdentifier)beginBackgroundTask;

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier;

@end
