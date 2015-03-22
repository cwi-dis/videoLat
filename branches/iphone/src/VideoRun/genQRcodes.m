//
//  genQRcodes.m
//  macMeasurements
//
//  Created by Jack Jansen on 21-08-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "genQRcodes.h"


@implementation GenQRcodes
- (GenQRcodes*)init
{
    self = [super init];
	symbol = ZBarcode_Create();
	symbol->input_mode = DATA_MODE;
//	symbol->width = width;
//	symbol->height = height;
	symbol->symbology = BARCODE_QRCODE;
	symbol->show_hrt = 0;
	strcpy(symbol->outfile, "none.xxx");
    return self;
}

- (void)dealloc
{
    if (symbol) ZBarcode_Delete(symbol);
    symbol = NULL;
}

- (void) gen: (void*)buffer width: (int)width height: (int)height code:(const char *)code
{
    int size = (width<height?width:height) - 60;
    int y_step = width;
    int x0 = (width-size)/2;
    int y0 = (height-size)/2;
    width = height = size;
    uint32_t *basepixelptr = (uint32_t *)buffer + x0;
    
    ZBarcode_Clear(symbol);
	int err = ZBarcode_Encode(symbol, (unsigned char *)code, (int)strlen(code));
	if (err == 0) {
		assert(width == height);
		//assert(symbol->width == symbol->height);
		symbol->scale = ((float)width / (float)symbol->width) / 2; // xxx the "2" is magic...
		err = ZBarcode_Buffer(symbol, 0);
		assert(symbol->bitmap_width <= width);
		assert(symbol->bitmap_height <= height);
	}
	if (err) {
		showWarningAlert(@"genQRcodes: ZBar_Encode error");
	} else {
        // Sigh... pixelbuf is 3 byte pixels, we need 4.
		for(int y=0; y < symbol->bitmap_height; y++) {
			uint32_t *pixelptr = basepixelptr+(y+y0)*y_step;
            for (int x=0; x < symbol->bitmap_width; x++) {
                if (symbol->bitmap[(x+(y*symbol->bitmap_width))*3])
                    *pixelptr++ = 0xffffffff;
                else
                    *pixelptr++ = 0x000000ff;
            }
        }
	}
}

@end
