//
//  findQRcodesCI.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 30/04/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "findQRcodesCI.h"

@implementation findQRcodesCI
@synthesize rect;

- (findQRcodesCI *)init
{
	self = [super init];
	if (self) {
		detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:nil];
	}
	return self;
}

- (char*) find: (void*)buffer width: (int)width height: (int)height format: (const char*)format size:(int)size
{
	assert(detector);
	NSData *imageData = [NSData dataWithBytes:buffer length:size];
	assert(strcmp(format, "argb") == 0);
	CIImage *image = [CIImage imageWithBitmapData:imageData bytesPerRow:width*4 size:CGSizeMake(width, height) format:kCIFormatARGB8 colorSpace:nil];
	NSArray *features = [detector featuresInImage:image];
	if (features == nil || features.count == 0) return NULL;
	if (features.count > 1) {
		NSLog(@"Warning: Multiple QR-codes detected");
	}
	CIQRCodeFeature *feature = features[0];
	lastDetection = feature.messageString;
	rect = feature.bounds;
	return (char *)[lastDetection UTF8String];
}

@end
