///
///  @file GenQRcode.h
///  @brief Generate QR-codes using CoreImage.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import "protocols.h"

///
/// QR code generator. Uses CoreImage to create greyscale image data prepresenting a QR code.
///
@interface GenQRcode : NSObject <OutputVideoGenProtocol> {
	CIFilter *qrcodegenerator;
}

- (GenQRcode*)init;
- (CIImage *) genImageForCode: (NSString *)code size:(int)size;

@end
