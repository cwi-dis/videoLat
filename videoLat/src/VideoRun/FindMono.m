//
//  FindMono.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 30/04/15.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "FindMono.h"

@implementation FindMono
@synthesize rect;

- (FindMono *)init
{
	self = [super init];
    if (self) {
        minInputLevel = 255;
        maxInputLevel = 0;
        sensitiveArea = NSorUIMakeRect(160, 120, 320, 240);
    }
	return self;
}


- (NSString *) find: (CVImageBufferRef)image
{
    OSType formatOSType = CVPixelBufferGetPixelFormatType(image);
    size_t w = CVPixelBufferGetWidth(image);
    //size_t h = CVPixelBufferGetHeight(image);
    //size_t size = CVPixelBufferGetDataSize(image);
    
    int pixelstep, pixelstart;
    bool isPlanar = false;
    if (formatOSType == kCVPixelFormatType_8IndexedGray_WhiteIsZero) {
        pixelstep = 1;
        pixelstart = 0;
    } else if (formatOSType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        pixelstep = 1;
        pixelstart = 0;
        isPlanar = true;
    } else if (formatOSType == 'yuvs' || formatOSType == 'yuv2') {
        pixelstep = 2;
        pixelstart = 0;
    } else if (formatOSType == kCVPixelFormatType_422YpCbCr8) {
        pixelstep = 2;
        pixelstart = 1;
    } else {
        NSLog(@"Unexpected newInputDone format %x", formatOSType);
        return nil;
    }
    
    CVPixelBufferLockBaseAddress(image, 0);
    void *buffer;
    if (isPlanar) {
        buffer = CVPixelBufferGetBaseAddressOfPlane(image, 0);
    } else {
        buffer = CVPixelBufferGetBaseAddress(image);
    }
    
    int minx, x, maxx, miny, y, maxy, ystep;
    minx = sensitiveArea.origin.x + (sensitiveArea.size.width/4);
    maxx = minx + (sensitiveArea.size.width/2);
    miny = sensitiveArea.origin.y + (sensitiveArea.size.height/4);
    maxy = miny + (sensitiveArea.size.width/2);
    ystep = (int)w*pixelstep;
    long long total = 0;
    long count = 0;
    for (y=miny; y<maxy; y++) {
        for (x=minx; x<maxx; x++) {
            unsigned char *pixelPtr = (unsigned char *)buffer + pixelstart + y*ystep + x*pixelstep;
            total += *pixelPtr;
            count++;
        }
    }
    
    CVPixelBufferUnlockBaseAddress(image, 0);
    
    int average = 0;
    if (count) average = (int)(total/count);
    // Complicated way to keep black and white level but adjust to changing camera apertures
    if (minInputLevel < 255) minInputLevel++;
    if (maxInputLevel > 0) maxInputLevel--;
    if (average < minInputLevel) minInputLevel = average;
    if (average > maxInputLevel) maxInputLevel = average;
    //bool foundColorIsWhite = average > (whitelevel+blacklevel) / 2;
    NSString *inputCode = @"mixed";
    int delta = (maxInputLevel - minInputLevel);
    if (delta > 10) {
        if (average < minInputLevel + (delta / 3))
            inputCode = @"black";
        if (average > maxInputLevel - (delta / 3))
            inputCode = @"white";
    }
    if (VL_DEBUG) NSLog(@" level %d (black %d white %d) found code %@", average, minInputLevel, maxInputLevel, inputCode);
    if (self.levelStatusView) {
#ifdef WITH_UIKIT
        self.levelStatusView.bInputNumericValue.text = [NSString stringWithFormat:@"%d", average];
        self.levelStatusView.bInputNumericMinValue.text = [NSString stringWithFormat:@"%d", minInputLevel];
        self.levelStatusView.bInputNumericMaxValue.text = [NSString stringWithFormat:@"%d", maxInputLevel];
        self.levelStatusView.bInputValue.on = [inputCode isEqualToString:@"white"];
#else
        NSCellStateValue iVal = NSMixedState;
        if ([inputCode isEqualToString:@"black"]) {
            iVal = NSOffState;
        } else if ([inputCode isEqualToString:@"white"]) {
            iVal = NSOnState;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.levelStatusView.bInputNumericValue setIntValue: average];
            [self.levelStatusView.bInputNumericMinValue setIntValue: self->minInputLevel];
            [self.levelStatusView.bInputNumericMaxValue setIntValue: self->maxInputLevel];
            [self.levelStatusView.bInputValue setState: iVal];
        });
#endif
    }
    return inputCode;
}


@end
