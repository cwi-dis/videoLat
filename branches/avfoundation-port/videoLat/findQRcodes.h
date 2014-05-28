//
//  findQRcodes.h
//  macMeasurements
//
//  Created by Jack Jansen on 21-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "zbar.h"

@interface FindQRcodes : NSObject {
    char *lastCode;
    void *scanner_hidden;
  @public
    NSRect rect;
}

@property(readonly) NSRect rect;

- (char*) find: (void*)buffer width: (int)width height: (int)height format: (const char*)format size:(int)size;

@end
