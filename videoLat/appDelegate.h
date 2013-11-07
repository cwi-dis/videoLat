//
//  appDelegate.h
//  videoLat
//
//  Created by Jack Jansen on 22-11-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "protocols.h"

@interface appDelegate : NSObject {
    IBOutlet id <OutputProtocol> output;
}

- (void)applicationWillTerminate:(id)application;
@end
