//
//  VideoMonoRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "VideoMonoRunManager.h"

@implementation VideoMonoRunManager

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Mono Roundtrip"];
    [BaseRunManager registerNib: @"VideoMonoRunManager" forMeasurementType: @"Video Mono Roundtrip"];
    // We also register ourselves for camera calibration. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Camera Input Calibrate"];
    [BaseRunManager registerNib: @"HardwareToCameraRunManager" forMeasurementType: @"Camera Input Calibrate"];
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Camera Input Calibrate (based on Screen)"];
    [BaseRunManager registerNib: @"CalibrateCameraFromScreenRunManager" forMeasurementType: @"Camera Input Calibrate (based on Screen)"];
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Screen Output Calibrate (based on Camera)"];
    [BaseRunManager registerNib: @"CalibrateScreenFromCameraRunManager" forMeasurementType: @"Screen Output Calibrate (based on Camera)"];
}

- (VideoMonoRunManager*)init
{
    self = [super init];
    if (self) {
		blacklevel = 255;
		whitelevel = 0;
    }
    return self;
}

- (void) awakeFromNib
{
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
    sensitiveArea = NSMakeRect(160, 120, 320, 240);
}

- (void) newInputDone: (void*)buffer width: (int)w height: (int)h format: (const char*)formatStr size: (int)size
{
    @synchronized(self) {
        assert(handlesInput);
		// Detect black/white
		int pixelstep, pixelstart;
		if (strcmp(formatStr, "Y800") == 0) {
			pixelstep = 1;
			pixelstart = 0;
		} else if (strcmp(formatStr, "YUYV") == 0) {
			pixelstep = 2;
			pixelstart = 0;
		} else if (strcmp(formatStr, "UYVY") == 0) {
			pixelstep = 2;
			pixelstart = 1;
		} else {
            NSLog(@"Unexpected newInputDone format %s", formatStr);
            return;
		}
        if (self.outputCompanion.outputCode == nil) return;
        
		int minx, x, maxx, miny, y, maxy, ystep;
		minx = sensitiveArea.origin.x + (sensitiveArea.size.width/4);
		maxx = minx + (sensitiveArea.size.width/2);
		miny = sensitiveArea.origin.y + (sensitiveArea.size.height/4);
		maxy = miny + (sensitiveArea.size.width/2);
		ystep = w*pixelstep;
		long long total = 0;
		long count = 0;
		for (y=miny; y<maxy; y++) {
			for (x=minx; x<maxx; x++) {
				unsigned char *pixelPtr = (unsigned char *)buffer + pixelstart + y*ystep + x*pixelstep;
				total += *pixelPtr;
				count++;
			}
		}
		int average = (int)(total/count);
		if (average < blacklevel) blacklevel = average;
		if (average > whitelevel) whitelevel = average;
		//bool foundColorIsWhite = average > (whitelevel+blacklevel) / 2;
        NSString *inputCode = @"mixed";
        int delta = (whitelevel - blacklevel);
        if (delta > 0) {
            if (average < blacklevel + (delta / 3))
                inputCode = @"black";
            if (average > whitelevel - (delta / 3))
                inputCode = @"white";
        }
        NSLog(@" level %d (black %d white %d) found code %@", average, blacklevel, whitelevel, inputCode);
        [self.bInputNumericValue setIntValue: average];
        [self.bInputNumericMinValue setIntValue: blacklevel];
        [self.bInputNumericMaxValue setIntValue: whitelevel];
        NSCellStateValue iVal = NSMixedState;
        if ([inputCode isEqualToString:@"black"]) {
            iVal = NSOffState;
        } else if ([inputCode isEqualToString:@"white"]) {
            iVal = NSOnState;
        }
        [self.bInputValue setState: iVal];
        
        if ([inputCode isEqualToString: self.outputCode]) {
            if (self.running) {
                [self.collector recordReception: inputCode at: inputStartTime];
                self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
                self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
                [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
                [self.outputCompanion triggerNewOutputValue];
            } else if (self.preRunning) {
                [self _prerunRecordReception: inputCode];
            }
        } else if (self.preRunning) {
            [self _prerunRecordNoReception];
        }
        inputStartTime = 0;
        
	}
}


- (CIImage *)newOutputStart
{
    @synchronized(self) {
        CIImage *newImage = nil;
        if (!self.running && !self.preRunning) {
            newImage = [CIImage imageWithColor:[CIColor colorWithRed:0.1 green:0.4 blue:0.5]];
            CGRect rect = {0, 0, 480, 480};
            newImage = [newImage imageByCroppingToRect: rect];
            return newImage;
        }
        outputStartTime = [self.clock now];
        prerunOutputStartTime = outputStartTime;
		if (currentColorIsWhite) {
			newImage = [CIImage imageWithColor:[CIColor colorWithRed:1 green:1 blue:1]];
            self.outputCode = @"white";
		} else {
			newImage = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]];
            self.outputCode = @"black";
        }
		CGRect rect = {0, 0, 480, 480};
		newImage = [newImage imageByCroppingToRect: rect];
		return newImage;
    }
}

- (void)triggerNewOutputValue
{
    currentColorIsWhite = !currentColorIsWhite;
	prerunOutputStartTime = 0;
	outputStartTime = 0;
	inputStartTime = 0;
    self.outputCode = nil;
	[self.outputView performSelectorOnMainThread:@selector(showNewData) withObject:nil waitUntilDone:NO ];
}
@end
