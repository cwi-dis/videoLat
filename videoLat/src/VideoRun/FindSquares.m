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
- (CIImage *)subImage: (CIImage *)src top: (float)top left: (float)left;
- (CIImage *)squareImageForFeature: (CIImage *)src feature: (CIRectangleFeature *)feature;
- (void)dumpImage: (CIImage *)src to: (NSString *)filename;
@end

@implementation FindSquares
@synthesize rect;

- (FindSquares *)init
{
	self = [super init];
    if (self) {
        // Could use options:@{CIDetectorAccuracy:CIDetectorAccuracyLow}
        detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil
                      options: @{
                                 CIDetectorAspectRatio: @(1.0)
                                 }
                    ];
    }
	return self;
}

- (NSString *) find: (CVImageBufferRef)image
{
    assert(detector);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:image];
    NSArray *features = [detector featuresInImage:ciImage];
    //NSLog(@"Found %lu squares", (unsigned long)features.count);
    if (features == nil || features.count == 0) {
        return NULL;
    }
    CIRectangleFeature *feature = features[0];
    CIImage *matchedSquareImage = [self squareImageForFeature:ciImage feature:feature];
    //NSLog(@"Square image width=%f height=%f", matchedSquareImage.extent.size.width, matchedSquareImage.extent.size.height);
    [self dumpImage: matchedSquareImage to: @"xxxjack-outerSquare.png"];
    // Now Find the five colored squares inside it
    int nFound = 0;
    float subRects[5][2] = {
        {0.25, 0},
        {0, 0.25},
        {0.25, 0.25},
        {0.5, 0.25},
        {0.25, 0.5}
    };
    
    for (int i=0; i<5; i++) {
        CIImage *midImage = [self subImage: matchedSquareImage top: subRects[i][0] left: subRects[i][1]];
        [self dumpImage: midImage to: [NSString stringWithFormat:@"xxxjack-inner%d.png", i]];
		NSLog(@"sub %d: midImage x=%f y=%f h=%f w=%f", i, midImage.extent.origin.x, midImage.extent.origin.y, midImage.extent.size.width, midImage.extent.size.height);
        // Find a square approximately in the right place
        features = [detector featuresInImage:midImage];
        if (features.count == 1) {
            nFound++;
            // Average the color in the area of the inner square
            feature = features[0];
            NSLog(@"sub %d: feature %@", i, feature);
            CIImage *subSquareImage = [self squareImageForFeature:midImage feature:feature];
			[self dumpImage: subSquareImage to: [NSString stringWithFormat:@"xxxjack-feature%d.png", i]];
            // Average the color
			CIVector *subExtent = [CIVector vectorWithX:subSquareImage.extent.origin.x
														 Y:subSquareImage.extent.origin.y
														 Z:subSquareImage.extent.size.width
														 W:subSquareImage.extent.size.height];
			CIFilter *subFilter = [CIFilter filterWithName:@"CIAreaAverage"
									keysAndValues:
									kCIInputImageKey, subSquareImage,
									kCIInputExtentKey, subExtent,
									nil
								];
			CIImage *subPixelImage = subFilter.outputImage;
			NSLog(@"sub %d: subSquareImage x=%f y=%f h=%f w=%f", i, subSquareImage.extent.origin.x, subSquareImage.extent.origin.y, subSquareImage.extent.size.width, subSquareImage.extent.size.height);
			NSLog(@"sub %d: subPixelImage x=%f y=%f h=%f w=%f", i, subPixelImage.extent.origin.x, subPixelImage.extent.origin.y, subPixelImage.extent.size.width, subPixelImage.extent.size.height);
			uint8_t subColorValues[4] = {42, 42, 42, 42};
			CGRect bounds = CGRectMake(0, 0, 1, 1);
			CIContext *subContext = [CIContext context];
			[subContext render:subPixelImage toBitmap:subColorValues rowBytes:sizeof(subColorValues) bounds:bounds format:kCIFormatRGBA8 colorSpace:NULL];
            NSLog(@"sub %d: %d %d %d %d", i, subColorValues[0], subColorValues[1], subColorValues[2], subColorValues[3]);
            // Convert to HLS or HSV or so
            // Get the primary/secondary value
        }
    }
    if (nFound != 5) return NULL;
    NSLog(@"Found %d subsquares", nFound);
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
#endif
}

- (CIImage *)subImage: (CIImage *)src top: (float)top left: (float)left
{
    CGRect rect = {
        {src.extent.origin.x + left*src.extent.size.width, src.extent.origin.y + top*src.extent.size.height},
        {0.5*src.extent.size.width, 0.5*src.extent.size.height}};
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
