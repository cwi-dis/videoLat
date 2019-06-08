///
///  @file genQRcodes.g
///  @brief Generate QR-codes using libzint.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "protocols.h"

///
/// QR code generator. Uses the zint library to create greyscale image data prepresenting a QR code.
///
@interface GenQRcodesCI : NSObject <OutputVideoGenProtocol> {
	CIFilter *qrcodegenerator;
}

- (GenQRcodesCI*)init;
- (CIImage *) genImageForCode: (NSString *)code;

@end
