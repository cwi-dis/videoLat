//
//  findQRcodes.m
//  macMeasurements
//
//  Created by Jack Jansen on 21-08-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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
    if (lastCode) free(lastCode);
    lastCode = NULL;
#if 0
    // There seems to be a problem deallocing the scanner.....
    zbar::ImageScanner *scanner = reinterpret_cast<zbar::ImageScanner *>(scanner_hidden);
    delete scanner;
#endif
}

- (char*) find: (void*)buffer width: (int)width height: (int)height format:(const char *)format size:(int)size
{
    zbar::ImageScanner *scanner = reinterpret_cast<zbar::ImageScanner *>(scanner_hidden);

	zbar::Image image(width, height, format, buffer, size);
	zbar::Image greyImage = image.convert(fourcc('Y', '8', '0', '0'));
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
            if (lastCode) free(lastCode);
            lastCode = strdup(decoded.c_str());
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
