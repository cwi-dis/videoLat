//
//  FindSquares.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 30/04/15.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "FindSquares.h"
#import "EventLogger.h"

@implementation FindSquares
@synthesize rect;

- (FindSquares *)init
{
	self = [super init];
    if (self) {
        minInputLevel = 255;
        maxInputLevel = 0;
        sensitiveArea = NSorUIMakeRect(0, 0, 0, 0);
        context = [CIContext context];
    }
	return self;
}

- (void) setSensitiveArea: (NSorUIRect)rect
{
    sensitiveArea = rect;
}

- (NSString *) find: (CVImageBufferRef)image
{
    int average = 0;
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:image];
    NSorUIRect rect = sensitiveArea;
    if (rect.size.width == 0 || rect.size.height == 0) {
        rect = ciImage.extent;
    }
    CIVector *ciExtent = [CIVector vectorWithX:rect.origin.x
                                             Y:rect.origin.y
                                             Z:rect.size.width
                                             W:rect.size.height];
    CIFilter *filter = [CIFilter filterWithName:@"CIAreaAverage"
                            keysAndValues:
                            kCIInputImageKey, ciImage,
                            kCIInputExtentKey, ciExtent,
                            nil
                        ];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    CIImage *outputImage = filter.outputImage;
    unsigned char bytes[4];
    CGRect bounds = CGRectMake(0, 0, 1, 1);
    [context render:outputImage toBitmap:bytes rowBytes:4 bounds:bounds format:kCIFormatL8 colorSpace:NULL];
    average = bytes[0];
    // Complicated way to keep black and white level but adjust to changing camera apertures
#if 1
    minInputLevel = ((int)minInputLevel*1.05)+1;
    if (minInputLevel > 255) minInputLevel = 255;
    maxInputLevel = ((int)maxInputLevel*0.95)-1;
    if (maxInputLevel < 0) maxInputLevel = 0;
#else
    if (minInputLevel < 255) minInputLevel++;
    if (maxInputLevel > 0) {maxInputLevel--;
#endif
    if (average < minInputLevel) minInputLevel = average;
    if (average > maxInputLevel) maxInputLevel = average;
    //bool foundColorIsWhite = average > (whitelevel+blacklevel) / 2;
    VL_LOG_EVENT(@"monoValue", 0LL, ([NSString stringWithFormat:@"%d range=(%d..%d)", average, minInputLevel, maxInputLevel]));
    NSString *inputCode = @"uncertain";
    int delta = (maxInputLevel - minInputLevel);
    if (delta > 10) {
        if (average < minInputLevel + (delta / 3))
            inputCode = @"black";
        if (average > maxInputLevel - (delta / 3))
            inputCode = @"white";
    } else {
        inputCode = @"undetectable";
    }
    VL_LOG_EVENT(@"monoCode", 0LL, inputCode);
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
