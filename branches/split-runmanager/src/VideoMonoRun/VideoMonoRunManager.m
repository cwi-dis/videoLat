//  VideoMonoRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "VideoMonoRunManager.h"

// How long we keep a random light level before changing it, when not running or
// prerunning. In microseconds.
#define IDLE_LIGHT_INTERVAL 200000

@implementation VideoMonoRunManager

- (int) initialPrerunCount { return 40; }
- (int) initialPrerunDelay { return 1000; }

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
		minInputLevel = 255;
		maxInputLevel = 0;
    }
    return self;
}

- (void) awakeFromNib
{
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
    sensitiveArea = NSMakeRect(160, 120, 320, 240);
}

- (void)restart
{
    @synchronized(self) {
		if (self.measurementType == nil) return;
        assert(handlesInput);
		[super restart];
		self.outputCode = @"mixed";
		minInputLevel = 255;
		maxInputLevel = 0;
    }
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
        [self.bInputNumericValue setIntValue: average];
        [self.bInputNumericMinValue setIntValue: minInputLevel];
        [self.bInputNumericMaxValue setIntValue: maxInputLevel];
        NSCellStateValue iVal = NSMixedState;
        if ([inputCode isEqualToString:@"black"]) {
            iVal = NSOffState;
        } else if ([inputCode isEqualToString:@"white"]) {
            iVal = NSOnState;
        }
        [self.bInputValue setState: iVal];

		if (![self.outputCompanion.outputCode isEqualToString:@"mixed"]) {
			if ([inputCode isEqualToString: self.outputCompanion.outputCode]) {
				if (self.running) {
					[self.collector recordReception: inputCode at: inputStartTime];
					self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
					self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
					[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
				} else if (self.preRunning) {
					[self _prerunRecordReception: inputCode];
				}
				[self.outputCompanion triggerNewOutputValue];
			} else if (self.preRunning) {
				[self _prerunRecordNoReception];
			}
		}
        inputStartTime = 0;
		// While idle, change output value once in a while
		if (!self.running && !self.preRunning) {
			[self.outputCompanion triggerNewOutputValue];
		}

	}
}


- (CIImage *)newOutputStart
{
    @synchronized(self) {
		assert(handlesOutput);
        CIImage *newImage = nil;
		if ([self.outputCode isEqualToString: @"white"]) {
			newImage = [CIImage imageWithColor:[CIColor colorWithRed:1 green:1 blue:1]];
		} else if ([self.outputCode isEqualToString: @"black"]) {
			newImage = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]];
        } else {
#if 1
			static double outputLevel;
			static uint64_t lastChange;
			if ([self.clock now] > lastChange + IDLE_LIGHT_INTERVAL) {
				outputLevel = (double)rand() / (double)RAND_MAX;
				lastChange = [self.clock now];
			}
            newImage = [CIImage imageWithColor:[CIColor colorWithRed:outputLevel green:outputLevel blue:outputLevel]];
#else
            newImage = [CIImage imageWithColor:[CIColor colorWithRed:0.1 green:0.4 blue:0.5]];
#endif
		}
		CGRect rect = {0, 0, 480, 480};
		newImage = [newImage imageByCroppingToRect: rect];
        if (outputStartTime) prevOutputStartTime = outputStartTime;
        outputStartTime = [self.clock now];
        prerunOutputStartTime = outputStartTime;
		if (VL_DEBUG) NSLog(@"VideoMonoRunManager.newOutputStart: returning %@ image", self.outputCode);
		return newImage;
    }
}

- (void)triggerNewOutputValue
{
	assert(handlesOutput);
    if (!self.running && !self.preRunning) {
        // Idle, show intermediate value
        self.outputCode = @"mixed";
    } else {
        if ([self.outputCode isEqualToString:@"black"]) {
            self.outputCode = @"white";
        } else {
            self.outputCode = @"black";
        }
    }
	prerunOutputStartTime = 0;
	outputStartTime = 0;
	inputStartTime = 0;
	[self.outputView performSelectorOnMainThread:@selector(showNewData) withObject:nil waitUntilDone:NO ];
}
@end
