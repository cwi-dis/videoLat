//
//  findQRcodes.h
//  macMeasurements
//
//  Created by Jack Jansen on 21-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"
#include "zbar.h"

@interface FindQRcodes : NSObject <FindProtocol> {
    char *lastCode;
    void *scanner_hidden;	// This is a C++ class, so we do some casting magic
    NSRect rect;
    BOOL configuring;
}

@property(readonly) NSRect rect;
@property BOOL configuring;

- (char*) find: (void*)buffer width: (int)width height: (int)height format: (const char*)format size:(int)size;

@end
