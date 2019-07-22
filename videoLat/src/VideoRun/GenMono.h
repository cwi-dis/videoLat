///
///  @file GenMono.h
///  @brief Generate monochrome images using CoreImage.
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
@interface GenMono : NSObject <OutputVideoGenProtocol> {
	CIFilter *qrcodegenerator;
}

- (GenMono *)init;
- (CIImage *) genImageForCode: (NSString *)code size:(int)size;

@end
