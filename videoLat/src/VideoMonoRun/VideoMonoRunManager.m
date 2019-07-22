//  VideoMonoRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "VideoMonoRunManager.h"
#import "EventLogger.h"

// How long we keep a random light level before changing it, when not running or
// prerunning. In microseconds.
#define IDLE_LIGHT_INTERVAL 200000

@implementation VideoMonoRunManager
@synthesize rect;

- (int) initialPrerunCount { return 40; }
- (int) initialPrerunDelay { return 1000; }

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Mono Roundtrip"];
    [BaseRunManager registerNib: @"VideoMonoRun" forMeasurementType: @"Video Mono Roundtrip"];
    // We also register ourselves for camera calibration. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Camera Calibrate"];
    [BaseRunManager registerNib: @"HardwareToCameraRun" forMeasurementType: @"Camera Calibrate"];
    
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Camera Calibrate using Calibrated Screen"];
    [BaseRunManager registerNib: @"CalibrateCameraFromScreenRun" forMeasurementType: @"Camera Calibrate using Calibrated Screen"];
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Screen Calibrate using Calibrated Camera"];
    [BaseRunManager registerNib: @"CalibrateScreenFromCameraRun" forMeasurementType: @"Screen Calibrate using Calibrated Camera"];

#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"Video Mono Roundtrip"];
#endif
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
    assert(self.finder == NULL);
    self.finder = self;
    assert(self.genner == NULL);
    self.genner = self;
    [super awakeFromNib];
    sensitiveArea = NSorUIMakeRect(160, 120, 320, 240);
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

- (void) _newOutputCode
{
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
}

#pragma mark RunOutputManagerProtocol

- (void)triggerNewOutputValue
{
	assert(handlesOutput);
	@synchronized(self) {
		outputCodeImage = nil;
		[self.outputView performSelectorOnMainThread:@selector(showNewData) withObject:nil waitUntilDone:NO ];
	}
}

- (CIImage *)newOutputStart
{
    @synchronized(self) {
        assert(handlesOutput);
        if (outputCodeImage)
            return outputCodeImage;
		[self _newOutputCode];
        outputCodeImage = [self.genner genImageForCode:self.outputCode size:480];
        tsOutEarliest = [self.clock now];
        tsOutLatest = 0;
        if (VL_DEBUG) NSLog(@"VideoMonoRunManager.newOutputStart: returning %@ image", self.outputCode);
        return outputCodeImage;
    }
}

#pragma mark RunInputManagerProtocol

- (void) newInputDone: (CVImageBufferRef)image
{
    @synchronized(self) {
        assert(handlesInput);
		if (self.outputCompanion.outputCode == nil) {
			if (VL_DEBUG) NSLog(@"newInputDone called, but no output code yet\n");
			return;
		}
        if (tsFrameLatest == 0) {
            NSLog(@"newInputDone called, but tsFrameLatest==0\n");
			assert(0);
            return;
        }

        NSString *inputCode = [self.finder find:image];
        
        if ([inputCode isEqualToString:@"mixed"]) {
            // Unsure what we have detected. Leave it be for a while then change.
            prevInputCodeDetectionCount++;
            if (prevInputCodeDetectionCount % 250 == 0) {
                NSLog(@"Received mixed code for too long. Generating new one.");
                [self.outputCompanion triggerNewOutputValue];
            }
        } else {
            if (self.outputCompanion.prevOutputCode && [inputCode isEqualToString:self.outputCompanion.prevOutputCode]) {
                if (VL_DEBUG) NSLog(@"Received old output code again: %@", inputCode);
            } else if (prevInputCode && [inputCode isEqualToString: prevInputCode]) {
                prevInputCodeDetectionCount++;
                if (VL_DEBUG) NSLog(@"Received same code as last reception: %@, count=%d", inputCode, prevInputCodeDetectionCount);
                if ((prevInputCodeDetectionCount % 250) == 0) {
                    showWarningAlert(@"Old code detected too often. Generating new one.");
                    [self.outputCompanion triggerNewOutputValue];
                }
            } else if ([inputCode isEqualToString: self.outputCompanion.outputCode]) {
				if (self.running) {
                    if (handlesOutput) {
                        assert(tsOutLatest);	// Must have been set before we can detect a qr-code
                    }
					assert(tsFrameLatest);	// Must have gotten an input frame before we get here
					uint64_t oldestTimePossible = tsOutLatest;	// Cannot detect before it has been generated
					if (tsFrameEarliest > oldestTimePossible) oldestTimePossible = tsFrameEarliest;
                    if (oldestTimePossible == 0) oldestTimePossible = tsFrameLatest;
					uint64_t bestTimeStamp = (oldestTimePossible + tsFrameLatest) / 2;
					NSLog(@"output between %lld and %lld (delta %lld), input between %lld and %lld (delta %lld) best %lld",
						tsOutEarliest, tsOutLatest, tsOutLatest-tsOutEarliest,
						tsFrameEarliest, tsFrameLatest, tsFrameLatest-tsFrameEarliest,
						bestTimeStamp);
					BOOL ok = [self.collector recordReception: self.outputCompanion.outputCode at: bestTimeStamp];
					VL_LOG_EVENT(@"reception", bestTimeStamp, self.outputCompanion.outputCode);
                    if (!ok) {
						showWarningAlert([NSString stringWithFormat:@"Received code %@ before it was transmitted", self.outputCompanion.outputCode]);
					}
					self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
					self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
					[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
				} else if (self.preRunning) {
					[self _prerunRecordReception: inputCode];
				}
                // Now let's remember it so we don't generate "bad code" messages
                // if we detect it a second time.
                prevInputCode = self.outputCompanion.outputCode;
                prevInputCodeDetectionCount = 0;
                if (VL_DEBUG) NSLog(@"Received: %@", self.outputCompanion.outputCode);
                // Now generate a new output code.
				[self.outputCompanion triggerNewOutputValueAfterDelay];
			} else {
				if (self.preRunning) {
					[self _prerunRecordNoReception];
				}
			}	
		}
#ifndef WITH_MEDIAN_TIMESTAMP
        inputStartTime = 0;
#endif
		// While idle, change output value once in a while
		if (!self.running && !self.preRunning) {
			[self.outputCompanion triggerNewOutputValue];
		}
	}
}

#pragma mark InputVideoFindProtocol

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
#ifdef WITH_UIKIT
    self.bInputNumericValue.text = [NSString stringWithFormat:@"%d", average];
    self.bInputNumericMinValue.text = [NSString stringWithFormat:@"%d", minInputLevel];
    self.bInputNumericMaxValue.text = [NSString stringWithFormat:@"%d", maxInputLevel];
    self.bInputValue.on = [inputCode isEqualToString:@"white"];
#else
    NSCellStateValue iVal = NSMixedState;
    if ([inputCode isEqualToString:@"black"]) {
        iVal = NSOffState;
    } else if ([inputCode isEqualToString:@"white"]) {
        iVal = NSOnState;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.bInputNumericValue setIntValue: average];
        [self.bInputNumericMinValue setIntValue: self->minInputLevel];
        [self.bInputNumericMaxValue setIntValue: self->maxInputLevel];
        [self.bInputValue setState: iVal];
    });
#endif
    return inputCode;
}

#pragma mark OutputVideoGenProtocol

// OutputVideoGenProtocol
- (CIImage *) genImageForCode: (NSString *)code size:(int)size
{
    CIImage *newImage;
    if ([code isEqualToString: @"white"]) {
        newImage = [CIImage imageWithColor:[CIColor colorWithRed:1 green:1 blue:1]];
    } else if ([code isEqualToString: @"black"]) {
        newImage = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]];
    } else {
        // Image with a random grey level
        static double outputLevel;
        static uint64_t lastChange;
        if ([self.clock now] > lastChange + IDLE_LIGHT_INTERVAL) {
            outputLevel = (double)rand() / (double)RAND_MAX;
            lastChange = [self.clock now];
        }
        newImage = [CIImage imageWithColor:[CIColor colorWithRed:outputLevel green:outputLevel blue:outputLevel]];
    }
    CGRect rect = {0, 0, 1, 1};
    newImage = [newImage imageByCroppingToRect: rect];
    return newImage;
}

@end
