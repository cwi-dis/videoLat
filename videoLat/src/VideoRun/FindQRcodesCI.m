//
//  FindQRcodesCI.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 30/04/15.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "FindQRcodesCI.h"

@implementation FindQRcodesCI
@synthesize rect;

- (FindQRcodesCI *)init
{
	self = [super init];
	if (self) {
		detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:nil];
	}
	return self;
}

- (NSString *) find: (CVImageBufferRef)image
{
	assert(detector);
	CIImage *ciImage = [CIImage imageWithCVPixelBuffer:image];
	NSArray *features = [detector featuresInImage:ciImage];
	if (features == nil || features.count == 0) return NULL;
	if (features.count > 1) {
		NSLog(@"Warning: Multiple QR-codes detected");
	}
	CIQRCodeFeature *feature = features[0];
	lastDetection = feature.messageString;
	rect = feature.bounds;
	return lastDetection;
}

@end
