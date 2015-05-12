///
///  @file genQRcodes.g
///  @brief Generate QR-codes using libzint.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "protocols.h"
#include "zint.h"

///
/// QR code generator. Uses the zint library to create greyscale image data prepresenting a QR code.
///
@interface GenQRcodes : NSObject <OutputVideoGenProtocol> {
    struct zint_symbol *symbol;	//!< Internal: reference to the zint symbol generator.
}

- (GenQRcodes*)init;
- (void) gen: (void*)buffer width: (int)width height: (int)height code: (const char *)code;
@end
