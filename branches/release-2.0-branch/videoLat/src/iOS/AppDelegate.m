//
//  AppDelegate.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 13/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "AppDelegate.h"
#import "EventLogger.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initVideolat];
#ifdef WITH_LOGGING
	NSURL *eventLogUrl =[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL: nil create:YES error:nil ];
	eventLogUrl = [eventLogUrl URLByAppendingPathComponent:@"videoLat.log"];
	[[EventLogger sharedLogger] save: eventLogUrl];
#endif
    return YES;
}

@end


@implementation UINavigationController (IOS6Rotation)

-(BOOL)shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}
@end