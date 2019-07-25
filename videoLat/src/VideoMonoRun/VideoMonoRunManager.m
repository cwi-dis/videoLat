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
    return self;
}

- (void) awakeFromNib
{
    assert(self.finder);
    assert(self.genner);
    [super awakeFromNib];
}

- (void)restart
{
    @synchronized(self) {
		if (self.measurementType == nil) return;
        assert(handlesInput);
		[super restart];
		self.outputCode = @"mixed";
        assert(self.finder);
        assert(self.genner);
        (void)[self.finder init];
        (void)[self.genner init];
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

- (CIImage *)newOutputStart
{
    @synchronized(self) {
        assert(handlesOutput);
        if (outputCodeImage)
            return outputCodeImage;
		[self _newOutputCode];
        outputCodeImage = [self.genner genImageForCode:self.outputCode size:480];
        outputFrameEarliestTimestamp = [self.clock now];
        outputFrameLatestTimestamp = 0;
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
                        assert(outputFrameLatestTimestamp);	// Must have been set before we can detect a qr-code
                    }
					BOOL ok = [self.collector recordReception: self.outputCompanion.outputCode at: inputFrameTimestamp];
					VL_LOG_EVENT(@"reception", inputFrameTimestamp, self.outputCompanion.outputCode);
                    inputFrameTimestamp = 0;
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
		// While idle, change output value once in a while
		if (!self.running && !self.preRunning) {
			[self.outputCompanion triggerNewOutputValue];
		}
	}
}

@end
