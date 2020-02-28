//
//  FindQRcode.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 30/04/15.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "FindQRcode.h"

@implementation FindQRcode
@synthesize rect;
@synthesize features;

- (FindQRcode *)init
{
	self = [super init];
	if (self) {
        // Could use options:@{CIDetectorAccuracy:CIDetectorAccuracyLow}
        detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:nil];
	}
	return self;
}

- (NSString *) find: (CVImageBufferRef)image
{
	assert(detector);
	CIImage *ciImage = [CIImage imageWithCVPixelBuffer:image];
	features = [detector featuresInImage:ciImage];
    if (features == nil || features.count == 0) {
#ifdef WITH_QRCODE_DEBUG
        static bool saveIt = true;
        if (saveIt) {
            CIContext *ctx = [CIContext context];
            NSURL *temporaryFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", [[NSUUID UUID] UUIDString]]]];
            [ctx writeJPEGRepresentationOfImage:ciImage toURL:temporaryFileURL colorSpace:CGColorSpaceCreateDeviceRGB() options:@{} error:nil];
            NSLog(@"No QR code found, saved to %@", temporaryFileURL);
        }
#endif
        return NULL;
    }
#if 0
    // This isn't necessarily an issue: sometimes the same feature is returned with 2 set of bounds (I think)
	if (features.count > 1) {
		NSLog(@"Warning: Multiple QR-codes detected");
        for(CIQRCodeFeature *feature in features) {
            NSLog(@"- Code: %@", feature.messageString);
        }
	}
#endif
	CIQRCodeFeature *feature = features[0];
	lastDetection = feature.messageString;
	rect = feature.bounds;
	return lastDetection;
}

@end
