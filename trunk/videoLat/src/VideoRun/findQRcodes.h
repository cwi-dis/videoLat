//
//  findQRcodes.h
//  macMeasurements
//
//  Created by Jack Jansen on 21-08-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"
#include "zbar.h"

///
/// Interface to the zbar library to detect QR codes in greyscale image data.
///
@interface FindQRcodes : NSObject <InputVideoFindProtocol> {
    char *lastCode;			//!< Most recent QR code found
    void *scanner_hidden;	//!< Pointer to the zbar scanner object.
    NSRect rect;			//!< Rectangle around most recent QR code found
    BOOL configuring;		//!< Unused?
}

@property(readonly) NSRect rect;	//!< Rectangle around most recent QR code found
@property BOOL configuring;			//!< Unused?

- (char*) find: (void*)buffer width: (int)width height: (int)height format: (const char*)format size:(int)size;

@end
