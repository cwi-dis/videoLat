///
///  @file genQRcodesCI.h
///  @brief Generate QR-codes using CoreImage.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import "protocols.h"

///
/// QR code generator. Uses CoreImage to create greyscale image data prepresenting a QR code.
///
@interface GenQRcodesCI : NSObject <OutputVideoGenProtocol> {
	CIFilter *qrcodegenerator;
}

- (GenQRcodesCI*)init;
- (CIImage *) genImageForCode: (NSString *)code;

@end
