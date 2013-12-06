//
//  OutputManager.m
//
//  Created by Jack Jansen on 27-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "VideoRunManager.h"
#import "PythonSwitcher.h"
#import "FindQRCodes.h"
#import "GenQRCodes.h"

//
// Prerun parameters.
// We want 10 consecutive catches, and we initially start with a 1ms delay (doubled at every failure)
#define PRERUN_COUNT 10
#define PRERUN_INITIAL_DELAY 1000

@implementation VideoRunManager
@synthesize mirrored;

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Roundtrip"];
    [BaseRunManager registerNib: @"VideoRunManager" forMeasurementType: @"Video Roundtrip"];
}

- (VideoRunManager*)init
{
	if (self) {
		current_qrcode = nil;
		outputAddedOverhead = 0;
		outputStartTime = 0;
		inputAddedOverhead = 0;
		inputStartTime = 0;
		outputCode = nil;
		outputCodeHasBeenReported = true;
		lastInputCode = nil;
		capturer = nil;
	}
    return self;
}

- (void) awakeFromNib
{
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
    @synchronized(self) {
//        [[settings window] setReleasedWhenClosed: false];

        genner = [[GenQRcodes alloc] init];
        finder = [[FindQRcodes alloc] init];
        statusView = measurementMaster.statusView;
        collector = measurementMaster.collector;
    }
}

- (void)selectMeasurementType: (NSString *)typeName
{
	[super selectMeasurementType:typeName];
	if (!selectionView) {
		// XXXJACK Make sure selectionView is active/visible
	}
	if (measurementType.isCalibration) {
		[selectionView.bBase setEnabled:NO];
		[selectionView.bPreRun setEnabled: YES];
	} else {
		NSArray *calibrationNames = measurementType.requires.measurementNames;
		[selectionView.bBase setEnabled:YES];
		[selectionView.bBase addItemsWithTitles:calibrationNames];
		if ([selectionView.bBase selectedItem]) {
			[selectionView.bPreRun setEnabled: YES];
		} else {
			[selectionView.bPreRun setEnabled: NO];
			NSAlert *alert = [NSAlert alertWithMessageText:@"No calibrations available."
				defaultButton:@"OK"
				alternateButton:nil
				otherButton:nil
				informativeTextWithFormat:@"%@ measurements should be based on a %@ calibration. Please calibrate first.",
					measurementType.name,
					measurementType.requires.name
				];
			[alert runModal];
		}
	}
	[selectionView.bRun setEnabled: NO];
	if (statusView) {
		[statusView.bStop setEnabled: NO];
	}
}

- (void)_triggerNewOutputValue
{
	// XXXJACK can be simplified
	[outputView showNewData];
}

- (void)reportDataCapturer: (id)capt
{
    capturer = capt;
}

- (IBAction)startPreMeasuring: (id)sender
{
	// First check that everything is OK with base measurement and such
	if (!measurementType.isCalibration) {
		// First check that a base measurement has been selected.
		NSString *errorMessage;
		NSMenuItem *baseItem = [selectionView.bBase selectedItem];
		NSString *baseName = [baseItem title];
		MeasurementType *baseType = measurementType.requires;
		MeasurementDataStore *baseStore = [baseType measurementNamed: baseName];
		if (baseType == nil) {
			errorMessage = @"No base (calibration) measurement selected.";
		} else {
			// Check that the base measurement is compatible with this measurement,
			if (![baseStore.inputDeviceID isEqualToString:capturer.deviceID]) {
				errorMessage = [NSString stringWithFormat:@"Base measurement uses input %@, current measurement uses %@", baseStore.inputDevice, capturer.deviceName];
			}
			if (![baseStore.outputDeviceID isEqualToString:outputView.deviceID]) {
				errorMessage = [NSString stringWithFormat:@"Base measurement uses output %@, current measurement uses %@", baseStore.outputDevice, outputView.deviceName];
			}
		}
		if (errorMessage) {
			NSAlert *alert = [NSAlert alertWithMessageText: @"Base calibration mismatch, are you sure you want to continue?"
				defaultButton:@"Cancel"
				alternateButton:@"Continue"
				otherButton:nil
				informativeTextWithFormat:@"%@", errorMessage];
			NSInteger button = [alert runModal];
			if (button == NSAlertDefaultReturn)
				return;
		}
		[collector.dataStore useCalibration:baseStore];
			
	}
	[selectionView.bPreRun setEnabled: NO];
	[selectionView.bRun setEnabled: NO];
	if (statusView) {
		[statusView.bStop setEnabled: NO];
	}
#if 1
    // Do actual prerunning
    prerunDelay = PRERUN_INITIAL_DELAY; // Start with 1ms delay (ridiculously low)
    prerunMoreNeeded = PRERUN_COUNT;
    self.preRunning = YES;
    [capturer startCapturing: YES];
    outputView.mirrored = self.mirrored;
    [self _triggerNewOutputValue];
#else
    // Forget about premeasuring
    [self stopPreMeasuring:self];
#endif
}

- (IBAction)stopPreMeasuring: (id)sender
{
    self.preRunning = NO;
    [capturer stopCapturing];
	[selectionView.bPreRun setEnabled: NO];
	[selectionView.bRun setEnabled: YES];
	if (!statusView) {
		// XXXJACK Make sure statusview is active/visible
	}
	[statusView.bStop setEnabled: NO];
}

- (IBAction)startMeasuring: (id)sender
{
    @synchronized(self) {
		[selectionView.bPreRun setEnabled: NO];
		[selectionView.bRun setEnabled: NO];
		if (!statusView) {
			// XXXJACK Make sure statusview is active/visible
		}
		[statusView.bStop setEnabled: YES];
        self.running = YES;
        [capturer startCapturing: NO];
        [collector startCollecting: self.measurementType.name input: capturer.deviceID name: capturer.deviceName output: outputView.deviceID name: outputView.deviceName];
        outputView.mirrored = self.mirrored;
        [self _triggerNewOutputValue];
    }
}
#pragma mark MeasurementOutputManagerProtocol

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
        if (outputStartTime == 0) outputStartTime = [collector now];
        outputAddedOverhead = 0;
        // We create a new image if either the previous one has been detected, or
        // if we are free-running.
        if (current_qrcode) {
            newImage = current_qrcode;
        } else {
            outputCode = [NSString stringWithFormat:@"%lld", outputStartTime];
            if (self.running) assert(outputCodeHasBeenReported);
            outputCodeHasBeenReported = false;
            if (delegate && [delegate respondsToSelector:@selector(newOutput:)]) {
                NSString *new = [delegate newOutput: outputCode];
                if (new) {
                    // Delegate decided to wait for something else, we transmit black
                    newImage = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]];
                    CGRect rect = {0, 0, 480, 480};
                    newImage = [newImage imageByCroppingToRect: rect];
                    current_qrcode = newImage;
                    outputCode = new;
                    return newImage;
                }
            }
            char *bitmapdata = (char*)malloc(480*480*4);
            memset(bitmapdata, 0xf0, 480*480*4);
            [genner gen: bitmapdata width: 480 height: 480 code: [outputCode UTF8String]];
            NSData *data = [NSData dataWithBytesNoCopy:bitmapdata length:sizeof(bitmapdata) freeWhenDone: YES];
            CGSize size = {480, 480};
            newImage = [CIImage imageWithBitmapData:data bytesPerRow:4*480 size:size format: kCIFormatARGB8 colorSpace: nil];
            current_qrcode = newImage;
        }
        return newImage;
    }
}

- (void) newOutputDone
{
    @synchronized(self) {
        if (outputStartTime == 0 || outputCodeHasBeenReported) return;
        assert(outputAddedOverhead < [collector now]);
        if (self.running) assert(strcmp([outputCode UTF8String], "BadCookie") != 0);
		uint64_t outputTime = [collector now] - outputAddedOverhead;
		if (self.running) {
			[collector recordTransmission: outputCode at: outputTime];
        }
        outputCodeHasBeenReported = true;
        outputStartTime = 0;
        outputAddedOverhead = 0;
    }
}

- (void) updateOutputOverhead: (double) deltaT
{
    @synchronized(self) {
        assert(deltaT < 1.0);
        if (outputStartTime != 0) {
            assert(outputAddedOverhead < [collector now]);
            outputAddedOverhead = (uint64_t)(deltaT*1000000.0);
        }
    }
}

#pragma mark MeasurementInputManagerProtocol

- (void)setFinderRect: (NSRect)theRect
{
//xyzzy	status.finderRect = theRect;
	[statusView update: self];
}


- (void) newInputStart
{
    @synchronized(self) {
//    assert(inputStartTime == 0);
        if (collector) {
            inputStartTime = [collector now];
            inputAddedOverhead = 0;
        }
    }
}

- (void) newInputDone
{
    @synchronized(self) {
        inputStartTime = 0;
        if (self.preRunning) {
            [self _prerunRecordNoReception];
        }
    }
}

- (void) _prerunRecordNoReception
{
#if 1
    if (VL_DEBUG) NSLog(@"Prerun no reception\n");
    if ([collector now] - outputStartTime > prerunDelay) {
        // No data found within alotted time. Double the time, reset the count, change mirroring
        if (VL_DEBUG) NSLog(@"outputStartTime=%llu, prerunDelay=%llu, mirrored=%d\n", outputStartTime, prerunDelay, self.mirrored);
        prerunDelay += (prerunDelay/4);
        prerunMoreNeeded = PRERUN_COUNT;
        self.mirrored = !self.mirrored;
        outputView.mirrored = self.mirrored;
        outputStartTime = 0;
        [self performSelectorOnMainThread: @selector(_triggerNewOutputValue) withObject: nil waitUntilDone: NO];
    } 
#endif
}

- (void) _prerunRecordReception: (NSString *)code
{
#if 1
    if (VL_DEBUG) NSLog(@"prerun reception %@\n", code);
    if (self.preRunning) {
        prerunMoreNeeded -= 1;
        if (VL_DEBUG) NSLog(@"preRunMoreMeeded=%d\n", prerunMoreNeeded);
        if (prerunMoreNeeded == 0) {
            [self performSelectorOnMainThread: @selector(stopPreMeasuring:) withObject: self waitUntilDone: NO];
        }
    }
#endif
}

- (void) newInputDone: (void*)buffer width: (int)w height: (int)h format: (const char*)formatStr size: (int)size
{
    @synchronized(self) {
        if (inputStartTime == 0) {
            if (VL_DEBUG) NSLog(@"newInputDone called, but inputStartTime==0\n");
            return;
        }
		if (outputCode == nil) {
			if (VL_DEBUG) NSLog(@"newInputDone called, but no output code yet\n");
			return;
		}
        assert(inputStartTime != 0);
            
        char *code = [finder find: buffer width: w height: h format: formatStr size:size];
        BOOL foundQRcode = (code != NULL);
        if (foundQRcode) {
			// Compare the code to what was expected.
			if (strcmp(code, [outputCode UTF8String]) == 0) {
				// outputStartTime = 0;
				// Correct. Prepare for creating a new QRcode.
				if (current_qrcode == nil) {
					// We found the last one already, don't count it again.
					return;
				}
				current_qrcode = nil;
				lastOutputCode = outputCode;
				if (self.running) {
                    assert(outputCodeHasBeenReported);
                    outputCode = [NSString stringWithFormat: @"BadCookie"];
                }
			} else if (strcmp(code, [lastOutputCode UTF8String]) == 0) {
				// We have received the previous code again. Ignore.
				//NSLog(@"Same old code again: %s", code);
			} else {
				// We have transmitted a code, but received a different one??
				NSLog(@"Bad data: expected %@, got %s", outputCode, code);
				inputAddedOverhead = 0;
				inputStartTime = 0;
				[self performSelectorOnMainThread: @selector(_triggerNewOutputValue) withObject: nil waitUntilDone: NO];
				return;
			}
            if (!lastInputCode || strcmp(code, [lastInputCode UTF8String]) != 0) {
                lastInputCode = [NSString stringWithUTF8String: code];
				if (self.running) {
					[collector recordReception: lastInputCode at: inputStartTime-inputAddedOverhead];
                } else if (self.preRunning) {
                    [self _prerunRecordReception: lastInputCode];
                }
            }
            inputAddedOverhead = 0;
            // Remember rectangle (for black/white detection)
//xyzzy            status.finderRect = finder.rect;
            [self performSelectorOnMainThread: @selector(_triggerNewOutputValue) withObject: nil waitUntilDone: NO];
        } else {
            inputAddedOverhead = 0;
            if (self.preRunning) {
                [self _prerunRecordNoReception];
            }
        }
        inputStartTime = 0;
		if (self.running) {
			statusView.detectCount = [NSString stringWithFormat: @"%d", collector.count];
			statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", collector.average / 1000.0, collector.stddev / 1000.0];
            [statusView update: self];
		}
    }
}

- (void) updateInputOverhead: (double) deltaT
{
    @synchronized(self) {
        if(inputStartTime != 0)
            inputAddedOverhead = (uint64_t)(deltaT*1000000.0);
    }
}


@end
