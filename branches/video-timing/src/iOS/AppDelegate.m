//
//  AppDelegate.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 13/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initVideolat];
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