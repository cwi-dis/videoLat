///
///  @file findQRcodes.h
///  @brief Detect QR-codes in video using libzbar.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "protocols.h"
#include "compat.h"
#include "zbar.h"

///
/// Interface to the zbar library to detect QR codes in greyscale image data.
///
@interface FindQRcodes : NSObject <InputVideoFindProtocol> {
    NSString *lastCode;			//!< Most recent QR code found
    void *scanner_hidden;	//!< Pointer to the zbar scanner object.
    NSorUIRect rect;			//!< Rectangle around most recent QR code found
}

@property(readonly) NSorUIRect rect;	//!< Rectangle around most recent QR code found

- (NSString*) find: (CVImageBufferRef)image;

@end
