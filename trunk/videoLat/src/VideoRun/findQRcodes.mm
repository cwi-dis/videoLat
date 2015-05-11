//
//  findQRcodes.m
//  macMeasurements
//
//  Created by Jack Jansen on 21-08-10.
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "findQRcodes.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
//#import <CoreServices/CoreServices.h>

#define fourcc(a, b, c, d)                      \
    ((uint32_t)(a) | ((uint32_t)(b) << 8) |     \
     ((uint32_t)(c) << 16) | ((uint32_t)(d) << 24))

@implementation FindQRcodes

@synthesize rect;

- (FindQRcodes*)init
{
    self = [super init];
    lastCode = NULL;
    rect = NSorUIMakeRect(0, 0, -1, -1);
    zbar::ImageScanner *scanner = new zbar::ImageScanner;
    scanner_hidden = (void*)scanner;

	// configure the scanner
	int rv;
	rv = scanner->set_config(zbar::ZBAR_NONE, zbar::ZBAR_CFG_ENABLE, 0);
	if (rv) {
        showWarningAlert(@"findQRcodes: set_config(0) returned error");
	}
	rv = scanner->set_config(zbar::ZBAR_QRCODE, zbar::ZBAR_CFG_ENABLE, 1);
	if (rv) {
        showWarningAlert(@"findQRcodes: set_config(ZBAR_QRCODE) returned error");
	}

    return self;
}

- (void)dealloc
{
#if 0
    // There seems to be a problem deallocing the scanner.....
    zbar::ImageScanner *scanner = reinterpret_cast<zbar::ImageScanner *>(scanner_hidden);
    delete scanner;
#endif
}

- (NSString *)find: (CVImageBufferRef)image
{
    zbar::ImageScanner *scanner = reinterpret_cast<zbar::ImageScanner *>(scanner_hidden);
	CVPixelBufferRef imagePixels = image;
	size_t width = CVPixelBufferGetWidth(imagePixels);
	size_t height = CVPixelBufferGetHeight(imagePixels);
	size_t size = CVPixelBufferGetDataSize(imagePixels);
	//
	// Decode the various types of pixel formats we have encountered, so far. Probably
	// new hardware will lead to more pixel formats that need to be catered for here.
	OSType formatOSType = CVPixelBufferGetPixelFormatType(imagePixels);
	BOOL isPlanar = NO;
	std::string format = "unknown";

	if (formatOSType == kCVPixelFormatType_32ARGB) {
		format = "RGB4";
	} else if (formatOSType == kCVPixelFormatType_32BGRA) {
		format = "BGR4";
	} else if (formatOSType == kCVPixelFormatType_8IndexedGray_WhiteIsZero) {
		format = "Y800";
	} else if (formatOSType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
		format = "Y800";
		isPlanar = YES;
	} else if (formatOSType == kCVPixelFormatType_422YpCbCr8) {
		format = "UYVY";
	} else if (formatOSType == 'yuvs' || formatOSType == 'yuv2') {
		// Not in the Apple header files, but generated by iSight on my MacBook??
		format = "YUYV";
	} else {
		// Unknown format??
		assert(0);
	}
	CVPixelBufferLockBaseAddress(imagePixels, 0);
		void *buffer = CVPixelBufferGetBaseAddress(imagePixels);
	if (isPlanar) {
		buffer = CVPixelBufferGetBaseAddressOfPlane(imagePixels, 0);
	}

	// Copy and convert into zbar image format.
	zbar::Image zbarImage((unsigned int)width, (unsigned int)height, format, buffer, size);

	// Unlock the memory in the CV image.
	CVPixelBufferUnlockBaseAddress(imagePixels, 0);

	// Convert the zbar image to grayscale
	zbar::Image greyImage = zbarImage.convert(fourcc('Y', '8', '0', '0'));

	// Find the QR-codes
	int n = scanner->scan(greyImage);
    assert(n >= 0);
	if (n > 0) {
		// Extract results
		for(zbar::Image::SymbolIterator symbol = greyImage.symbol_begin();
			symbol != greyImage.symbol_end();
			++symbol)
		{
			std::string decoded = symbol->get_data();
            int x=0, y=0, i=0;
            int minx=9999, maxx=-1, miny=9999, maxy=-1;
            do {
                x = symbol->get_location_x(i);
                y = symbol->get_location_y(i);
                if (x < 0 || y < 0) break;
                if (x<minx) minx = x;
                if (y<miny) miny = y;
                if (x>maxx) maxx = x;
                if (y>maxy) maxy = y;
                i++;
            } while (x>=0 && y>=0);
            if (i >= 3) 
                rect = NSorUIMakeRect(minx, miny, (maxx-minx), (maxy-miny));
            lastCode = [NSString stringWithUTF8String:decoded.c_str()];
			return lastCode;
		}
		showWarningAlert(@"QRCode detection: was promised %d symbols but found none??");
        assert(0);
        return NULL;
	} else {
        rect = NSorUIMakeRect(-1, -1, -1, -1);
        return NULL;
	}
}
@end
