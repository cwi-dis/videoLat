//
//  FindSquares.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 30/04/15.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "FindSquares.h"
#import "EventLogger.h"

@interface FindSquares()
- (CIImage *)subImage: (CIImage *)src left: (float)left top: (float)top right: (float)right bottom: (float)bottom;
- (CIImage *)squareImageForFeature: (CIImage *)src feature: (CIRectangleFeature *)feature;
- (void)dumpImage: (CIImage *)src to: (NSString *)filename;
@end

@implementation FindSquares
@synthesize rect;
@synthesize features;

- (FindSquares *)init
{
	self = [super init];
    if (self) {
        // Could use options:@{CIDetectorAccuracy:CIDetectorAccuracyLow}
        detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil
                                      options: @{
                                                 CIDetectorAccuracy : CIDetectorAccuracyHigh,
                                                 CIDetectorFocalLength: @0.0,
                                                 CIDetectorAspectRatio: @1.0,
                                                 CIDetectorMaxFeatureCount: @1
                                                 }
                    ];
    }
	return self;
}

- (NSString *) find: (CVImageBufferRef)image
{
    assert(detector);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:image];
    features = [detector featuresInImage:ciImage];
    if (features == nil || features.count != 1) {
        return NULL;
    }
    NSLog(@"Found %lu squares", (unsigned long)features.count);
    CIRectangleFeature *feature = features[0];
    CIImage *matchedSquareImage = [self squareImageForFeature:ciImage feature:feature];
    //NSLog(@"Square image width=%f height=%f", matchedSquareImage.extent.size.width, matchedSquareImage.extent.size.height);
    [self dumpImage: matchedSquareImage to: @"xxxjack-outerSquare.png"];
    // Now find the inner square
    CIImage *innerSearchArea = [self subImage: matchedSquareImage left: 0.2 top: 0.2 right: 0.8 bottom: 0.8];
    [self dumpImage: innerSearchArea to: @"xxxjack-innerSearch.png"];
    NSArray<CIRectangleFeature *> *innerFeatures = [detector featuresInImage:innerSearchArea];
    if (innerFeatures == nil || innerFeatures.count != 1) {
        return NULL;
    }
    NSLog(@"Found %lu inner squares", (unsigned long)features.count);
    feature = innerFeatures[0];
    float x0 = (feature.topLeft.x+feature.bottomLeft.x) / (2*innerSearchArea.extent.size.width);
    float x1 = (feature.topRight.x+feature.bottomRight.x) / (2*innerSearchArea.extent.size.width);
    float y0 = (feature.bottomLeft.y+feature.bottomRight.y) / (2*innerSearchArea.extent.size.height);
    float y1 = (feature.topLeft.y+feature.topRight.y) / (2*innerSearchArea.extent.size.height);
    // Now convert from innerSearchArea to matchedSquareImage
    x0 = 0.2 + x0 * 0.6;
    x1 = 0.2 + x1 * 0.6;
    y0 = 0.2 + y0 * 0.6;
    y1 = 0.2 + y1 * 0.6;
    NSLog(@" x0=%f x1=%f y0=%f y1=%f", x0, x1, y0, y1);
    float edge = 0.1;
    float subRects[5][4] = {
        {x0+edge, 0, x1-edge, y0-edge},    // Top
        {0, y0+edge, x0-edge, y1-edge},    // Left
        {x0+edge, y0+edge, x1-edge, y1-edge},   // Center
        {x1+edge, y0+edge, 1, y1-edge},    // Right
        {x0+edge, y1+edge, x1-edge, 1}     // Bottom
    };
    // Compute the hues of each of the squares
    float lightness[5];
    float hue[5];
    for (int i=0; i<5; i++) {
        CIImage *midImage = [self subImage: matchedSquareImage left: subRects[i][0] top: subRects[i][1] right: subRects[i][2] bottom: subRects[i][3]];
        [self dumpImage: midImage to: [NSString stringWithFormat:@"xxxjack-inner%d.png", i]];
		NSLog(@"sub %d: midImage x=%f y=%f h=%f w=%f", i, midImage.extent.origin.x, midImage.extent.origin.y, midImage.extent.size.width, midImage.extent.size.height);
        CIVector *subExtent = [CIVector vectorWithX:midImage.extent.origin.x
                                                     Y:midImage.extent.origin.y
                                                     Z:midImage.extent.size.width
                                                     W:midImage.extent.size.height];
        CIFilter *subFilter = [CIFilter filterWithName:@"CIAreaAverage"
                                keysAndValues:
                                kCIInputImageKey, midImage,
                                kCIInputExtentKey, subExtent,
                                nil
                            ];
        CIImage *subPixelImage = subFilter.outputImage;
        NSLog(@"sub %d: subPixelImage x=%f y=%f h=%f w=%f", i, subPixelImage.extent.origin.x, subPixelImage.extent.origin.y, subPixelImage.extent.size.width, subPixelImage.extent.size.height);
        uint8_t subColorValues[4] = {42, 42, 42, 42};
        CGRect bounds = CGRectMake(0, 0, 1, 1);
        CIContext *subContext = [CIContext context];
        [subContext render:subPixelImage toBitmap:subColorValues rowBytes:sizeof(subColorValues) bounds:bounds format:kCIFormatRGBA8 colorSpace:NULL];
        NSLog(@"sub %d: %d %d %d %d", i, subColorValues[0], subColorValues[1], subColorValues[2], subColorValues[3]);
        // Convert to HLS or HSV or so
        // Get the primary/secondary value
        float r = subColorValues[0] / 255.0;
        float g = subColorValues[1] / 255.0;
        float b = subColorValues[2] / 255.0;
        float maxColor = fmax(r, fmax(g, b));
        float minColor = fmin(r, fmin(g, b));
        float rangeColor = maxColor-minColor;
        lightness[i] = (maxColor+minColor)/2;
        float hPrime = 0;
        if (rangeColor == 0) {
            hPrime = 0; // Undefined really
        } else if (r == maxColor) {
            hPrime = (g-b)/rangeColor;
        } else if (g == maxColor) {
            hPrime = 2+(b-r)/rangeColor;
        } else if (b == maxColor) {
            hPrime = 4+(r-g)/rangeColor;
        }
        while (hPrime < 0) hPrime += 6;
        while (hPrime > 6) hPrime -= 6;
        hue[i] = hPrime*60;
        NSLog(@"sub %d: hue=%f lightness=%f", i, hue[i], lightness[i]);
    }
    return NULL;
#if 0
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
    minInputLevel = ((int)minInputLevel*1.05)+1;
    if (minInputLevel > 255) minInputLevel = 255;
    maxInputLevel = ((int)maxInputLevel*0.95)-1;
    if (maxInputLevel < 0) maxInputLevel = 0;
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
#endif
}

- (CIImage *)subImage: (CIImage *)src left: (float)left top: (float)top right: (float)right bottom: (float)bottom
{
    float x0 = src.extent.origin.x + left*src.extent.size.width;
    float y0 = src.extent.origin.y + top*src.extent.size.height;
    float x1 = src.extent.origin.x + right*src.extent.size.width;
    float y1 = src.extent.origin.y + bottom*src.extent.size.height;
    CGRect rect = {
        {x0, y0},
        {x1-x0, y1-y0}};
    return [src imageByCroppingToRect:rect];
}

- (void)dumpImage: (CIImage *)src to: (NSString *)filename
{
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]initWithCIImage:src];
    NSData *imageData = [rep representationUsingType:NSPNGFileType properties:nil];
    bool ok = [imageData writeToFile:filename atomically:false];
    assert(ok);
}

- (CIImage *)squareImageForFeature: (CIImage *)src feature: (CIRectangleFeature *)feature
{
    CIVector *topLeft = [CIVector vectorWithCGPoint: feature.topLeft];
    CIVector *topRight = [CIVector vectorWithCGPoint: feature.topRight];
    CIVector *bottomLeft = [CIVector vectorWithCGPoint: feature.bottomLeft];
    CIVector *bottomRight = [CIVector vectorWithCGPoint: feature.bottomRight];
    CIFilter *convertToSquare = [CIFilter filterWithName:@"CIPerspectiveCorrection" keysAndValues:
                                 @"inputTopLeft", topLeft,
                                 @"inputTopRight", topRight,
                                 @"inputBottomLeft", bottomLeft,
                                 @"inputBottomRight", bottomRight,
                                 @"inputImage", src,
                                 nil];
    CIImage *matchedSquareImage = convertToSquare.outputImage;
    return matchedSquareImage;
}
@end
