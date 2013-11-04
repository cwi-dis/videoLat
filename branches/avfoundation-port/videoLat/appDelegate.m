//
//  appDelegate.m
//  videoLat
//
//  Created by Jack Jansen on 22-11-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "appDelegate.h"


@implementation appDelegate
- (void)applicationWillTerminate:(id)application
{
    if (output) [output terminate];
}
@end
