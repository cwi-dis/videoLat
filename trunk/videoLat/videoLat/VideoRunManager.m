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
#import <sys/sysctl.h>

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
		outputStartTime = 0;
		outputAddedOverhead = 0;
        prevOutputStartTime = 0;
		outputCode = nil;
        prevOutputCode = nil;
		outputCodeImage = nil;

        inputStartTime = 0;
        inputAddedOverhead = 0;
        prevInputStartTime = 0;
        prevInputCode = nil;
	}
    return self;
}

- (void)dealloc
{
}

- (void) awakeFromNib
{
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
    @synchronized(self) {
//        [[settings window] setReleasedWhenClosed: false];

        genner = [[GenQRcodes alloc] init];
        finder = [[FindQRcodes alloc] init];
        self.statusView = self.measurementMaster.statusView;
        self.collector = self.measurementMaster.collector;
    }
}

- (void)selectMeasurementType: (NSString *)typeName
{
	[super selectMeasurementType:typeName];
	if (!self.selectionView) {
		// XXXJACK Make sure selectionView is active/visible
	}
	if (measurementType.isCalibration) {
		[self.selectionView.bBase setEnabled:NO];
		[self.selectionView.bPreRun setEnabled: YES];
	} else {
		NSArray *calibrationNames = measurementType.requires.measurementNames;
		[self.selectionView.bBase setEnabled:YES];
		[self.selectionView.bBase addItemsWithTitles:calibrationNames];
		if ([self.selectionView.bBase selectedItem]) {
			[self.selectionView.bPreRun setEnabled: YES];
		} else {
			[self.selectionView.bPreRun setEnabled: NO];
			NSAlert *alert = [NSAlert alertWithMessageText:@"No calibrations available."
				defaultButton:@"OK"
				alternateButton:nil
				otherButton:nil
				informativeTextWithFormat:@"%@ measurements should be based on a %@ calibration. Please calibrate first.",
					measurementType.name,
					measurementType.requires.name
				];
			[alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
		}
	}
	[self.selectionView.bRun setEnabled: NO];
	if (self.statusView) {
		[self.statusView.bStop setEnabled: NO];
	}
}

- (void)_triggerNewOutputValue
{
	// XXXJACK can be simplified
	[self.outputView showNewData];
}

- (void)reportDataCapturer: (id)capt
{
    self.capturer = capt;
}

- (IBAction)startPreMeasuring: (id)sender
{
	// First check that everything is OK with base measurement and such
	if (!measurementType.isCalibration) {
		// First check that a base measurement has been selected.
		NSString *errorMessage;
		NSMenuItem *baseItem = [self.selectionView.bBase selectedItem];
		NSString *baseName = [baseItem title];
		MeasurementType *baseType = measurementType.requires;
		MeasurementDataStore *baseStore = [baseType measurementNamed: baseName];
		if (baseType == nil) {
			errorMessage = @"No base (calibration) measurement selected.";
		} else {
			// Check that the base measurement is compatible with this measurement,
			char hwName_c[100] = "unknown";
			size_t len = sizeof(hwName_c);
			sysctlbyname("hw.model", hwName_c, &len, NULL, 0);
			NSString *hwName = [NSString stringWithUTF8String:hwName_c];
			if (![baseStore.machineID isEqualToString:hwName]) {
				errorMessage = [NSString stringWithFormat:@"Base measurement done on %@, current hardware is %@", baseStore.machine, hwName];
			}
			if (![baseStore.inputDeviceID isEqualToString:self.capturer.deviceID]) {
				errorMessage = [NSString stringWithFormat:@"Base measurement uses input %@, current measurement uses %@", baseStore.inputDevice, self.capturer.deviceName];
			}
			if (![baseStore.outputDeviceID isEqualToString:self.outputView.deviceID]) {
				errorMessage = [NSString stringWithFormat:@"Base measurement uses output %@, current measurement uses %@", baseStore.outputDevice, self.outputView.deviceName];
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
		[self.collector.dataStore useCalibration:baseStore];
			
	}
	[self.selectionView.bPreRun setEnabled: NO];
	[self.selectionView.bRun setEnabled: NO];
	if (self.statusView) {
		[self.statusView.bStop setEnabled: NO];
	}
#if 1
    // Do actual prerunning
    prerunDelay = PRERUN_INITIAL_DELAY; // Start with 1ms delay (ridiculously low)
    prerunMoreNeeded = PRERUN_COUNT;
    self.preRunning = YES;
    [self.capturer startCapturing: YES];
    self.outputView.mirrored = self.mirrored;
    [self _triggerNewOutputValue];
#else
    // Forget about premeasuring
    [self stopPreMeasuring:self];
#endif
}

- (IBAction)stopPreMeasuring: (id)sender
{
    self.preRunning = NO;
    [self.capturer stopCapturing];
	[self.selectionView.bPreRun setEnabled: NO];
	[self.selectionView.bRun setEnabled: YES];
	if (!self.statusView) {
		// XXXJACK Make sure statusview is active/visible
	}
	[self.statusView.bStop setEnabled: NO];
}

- (IBAction)startMeasuring: (id)sender
{
    @synchronized(self) {
		[self.selectionView.bPreRun setEnabled: NO];
		[self.selectionView.bRun setEnabled: NO];
		if (!self.statusView) {
			// XXXJACK Make sure statusview is active/visible
		}
		[self.statusView.bStop setEnabled: YES];
        self.running = YES;
        [self.capturer startCapturing: NO];
        [self.collector startCollecting: self.measurementType.name input: self.capturer.deviceID name: self.capturer.deviceName output: self.outputView.deviceID name: self.outputView.deviceName];
        self.outputView.mirrored = self.mirrored;
        [self _triggerNewOutputValue];
    }
}
#pragma mark MeasurementOutputManagerProtocol

- (CIImage *)newOutputStart
{
    // Called from the redraw routine, should generate a new output code only when needed.
    @synchronized(self) {
        
        // If we are not running we should display a blue-grayish square
        if (!self.running && !self.preRunning) {
            CIImage *idleImage = [CIImage imageWithColor:[CIColor colorWithRed:0.1 green:0.4 blue:0.5]];
            CGRect rect = {0, 0, 480, 480};
            idleImage = [idleImage imageByCroppingToRect: rect];
            return idleImage;
        }
        
        // If we have already generated a QR code that hasn't been detected yet we return that.
        if (outputCodeImage)
            return outputCodeImage;
        
        // Generate a new image. First obtain the timestamp.
        prevOutputStartTime = outputStartTime;
        outputStartTime = [self.collector now];
        prerunOutputStartTime = outputStartTime;
        outputAddedOverhead = 0;
        
        // Sanity check: times should be monotonically increasing
        if (prevOutputStartTime && prevOutputStartTime >= outputStartTime) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: output clock not monotonically increasing."
                    defaultButton:@"OK"
                    alternateButton:nil
                    otherButton:nil
                    informativeTextWithFormat:@"Previous value was %lld, current value is %lld",
                              (long long)prevOutputStartTime,
                              (long long)outputStartTime];
            [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
        }
        
        // Generate the new output code
        outputCode = [NSString stringWithFormat:@"%lld", outputStartTime];

#if 0
        if (delegate && [delegate respondsToSelector:@selector(newOutput:)]) {
            NSString *new = [delegate newOutput: outputCode];
            if (new) {
                // Delegate decided to wait for something else, we transmit black
                newImage = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]];
                CGRect rect = {0, 0, 480, 480};
                newImage = [newImage imageByCroppingToRect: rect];
                outputCodeImage = newImage;
                outputCode = new;
                return newImage;
            }
        }
#endif
        int bpp = 4;
        CGSize size = {480, 480};
        char *bitmapdata = (char*)malloc(size.width*size.height*bpp);
        memset(bitmapdata, 0xf0, size.width*size.height*bpp);
        [genner gen: bitmapdata width:size.width height:size.height code:[outputCode UTF8String]];
        NSData *data = [NSData dataWithBytesNoCopy:bitmapdata length:sizeof(bitmapdata) freeWhenDone: YES];
        outputCodeImage = [CIImage imageWithBitmapData:data bytesPerRow:bpp*size.width size:size format:kCIFormatARGB8 colorSpace:nil];
        return outputCodeImage;
    }
}

- (void) newOutputDone
{
    @synchronized(self) {
        if (outputStartTime == 0) return;
        assert(outputAddedOverhead < [self.collector now]);
		uint64_t outputTime = [self.collector now] - outputAddedOverhead;
		if (self.running) {
			[self.collector recordTransmission: outputCode at: outputTime];
        }
        outputStartTime = 0;
        outputAddedOverhead = 0;
    }
}

- (void) updateOutputOverhead: (double) deltaT
{
    @synchronized(self) {
        assert(deltaT > 0);
        assert(deltaT < 1.0);
        if (outputStartTime != 0) {
            assert(outputAddedOverhead < [self.collector now]);
            outputAddedOverhead = (uint64_t)(deltaT*1000000.0);
        }
    }
}

#pragma mark MeasurementInputManagerProtocol

- (void)setFinderRect: (NSRect)theRect
{
#if 0
//xyzzy	status.finderRect = theRect;
	[self.statusView update: self];
#endif
}


- (void) newInputStart
{
    @synchronized(self) {
//    assert(inputStartTime == 0);
        if (self.collector) {
            prevInputStartTime = inputStartTime;
            inputStartTime = [self.collector now];
            inputAddedOverhead = 0;

            // Sanity check: times should be monotonically increasing
            if (prevInputStartTime && prevInputStartTime >= inputStartTime) {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: input clock not monotonically increasing."
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"Previous value was %lld, current value is %lld",
                                  (long long)prevInputStartTime,
                                  (long long)inputStartTime];
                [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
            }
        }
    }
}

// XXXJACK this method can go!
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
    if (prerunOutputStartTime != 0 && [self.collector now] - prerunOutputStartTime > prerunDelay) {
        // No data found within alotted time. Double the time, reset the count, change mirroring
        if (VL_DEBUG) NSLog(@"outputStartTime=%llu, prerunDelay=%llu, mirrored=%d\n", outputStartTime, prerunDelay, self.mirrored);
        prerunDelay *= 2;
        prerunMoreNeeded = PRERUN_COUNT;
        self.mirrored = !self.mirrored;
        self.outputView.mirrored = self.mirrored;
        prerunOutputStartTime = 0;
        outputStartTime = 0;
        outputCodeImage = nil;
        self.statusView.detectCount = [NSString stringWithFormat: @"%d more, mirrored=%d", prerunMoreNeeded, (int)self.mirrored];
		self.statusView.detectAverage = @"";
        [self.statusView update: self];
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
        self.statusView.detectCount = [NSString stringWithFormat: @"%d more, mirrored=%d", prerunMoreNeeded, (int)self.mirrored];
		self.statusView.detectAverage = @"";
        [self.statusView update: self];
        if (VL_DEBUG) NSLog(@"preRunMoreMeeded=%d\n", prerunMoreNeeded);
        if (prerunMoreNeeded == 0) {
            self.statusView.detectCount = @"";
			self.statusView.detectAverage = @"";
            [self.statusView update: self];
            [self performSelectorOnMainThread: @selector(stopPreMeasuring:) withObject: self waitUntilDone: NO];
        }
    }
#endif
}

- (void) newInputDone: (void*)buffer width: (int)w height: (int)h format: (const char*)formatStr size: (int)size
{
    @synchronized(self) {
		if (outputCode == nil) {
			if (VL_DEBUG) NSLog(@"newInputDone called, but no output code yet\n");
			return;
		}
        if (inputStartTime == 0) {
            NSLog(@"newInputDone called, but inputStartTime==0\n");
            assert(0);
            return;
        }
        
        char *code = [finder find: buffer width: w height: h format: formatStr size:size];
        BOOL foundQRcode = (code != NULL);
        if (foundQRcode) {
            
			// Compare the code to what was expected.
            if (prevOutputCode && strcmp(code, [prevOutputCode UTF8String]) == 0) {
				//NSLog(@"Received old output code again: %s", code);
            } else if (prevInputCode && strcmp(code, [prevInputCode UTF8String]) == 0) {
                //NSLog(@"Received same code as last reception: %s", code);
                prevInputCodeDetectionCount++;
                if ((prevInputCodeDetectionCount % 250) == 0) {
                    NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: no new QR code generated."
                                                     defaultButton:@"OK"
                                                   alternateButton:nil
                                                       otherButton:nil
                                         informativeTextWithFormat:@"QR-code %@ detected %d times. Generating new one.",
                                      prevInputCode, prevInputCodeDetectionCount];
                    [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
                    outputCodeImage = nil;
                    inputAddedOverhead = 0;
                    inputStartTime = 0;
                    [self performSelectorOnMainThread: @selector(_triggerNewOutputValue) withObject: nil waitUntilDone: NO];
                }
            } else if (strcmp(code, [outputCode UTF8String]) == 0) {
				// Correct code found.
                
                // Let's first report it.
				if (self.running) {
					BOOL ok = [self.collector recordReception: outputCode at: inputStartTime-inputAddedOverhead];
                    if (!ok) {
                        NSAlert *alert = [NSAlert alertWithMessageText:@"Reception before transmission."
                                                         defaultButton:@"OK"
                                                       alternateButton:nil
                                                           otherButton:nil
                                             informativeTextWithFormat:@"Code %@ was transmitted at %lld, but received at %lld. (Actually received at %lld, but with reported overhead of %lld)",
                                          outputCode,
                                          (long long)prerunOutputStartTime,
                                          (long long)inputStartTime-inputAddedOverhead,
                                          (long long)inputStartTime,
                                          (long long)inputAddedOverhead];
                        [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
                    }
                } else if (self.preRunning) {
                    [self _prerunRecordReception: outputCode];
                }
                // Now do a sanity check that it is greater than the previous detected code
                if (prevInputCode && [prevInputCode length] >= [outputCode length] && [prevInputCode compare:outputCode] >= 0) {
                    NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: input QR-code not monotonically increasing."
                                                     defaultButton:@"OK"
                                                   alternateButton:nil
                                                       otherButton:nil
                                         informativeTextWithFormat:@"Previous value was %@, current value is %@",
                                            prevInputCode, outputCode];
                    [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
                }
                // Now let's remember it so we don't generate "bad code" messages
                // if we detect it a second time.
                prevInputCode = outputCode;
                prevInputCodeDetectionCount = 0;
                
                // Now generate a new output code.
                outputCodeImage = nil;
                inputAddedOverhead = 0;
                inputStartTime = 0;
                [self performSelectorOnMainThread: @selector(_triggerNewOutputValue) withObject: nil waitUntilDone: NO];
			} else {
				// We have transmitted a code, but received a different one??
                if (self.running) {
                    NSLog(@"Bad data: expected %@, got %s", outputCode, code);
                    NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: received unexpected QR-code."
                                                     defaultButton:@"OK"
                                                   alternateButton:nil
                                                       otherButton:nil
                                         informativeTextWithFormat:@"Expected value was %@, received %s",
                                      outputCode, code];
                    [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
                }
				[self performSelectorOnMainThread: @selector(_triggerNewOutputValue) withObject: nil waitUntilDone: NO];
			}
        } else {
             
            if (self.preRunning) {
                [self _prerunRecordNoReception];
            }
        }
        inputAddedOverhead = 0;
        inputStartTime = 0;
		if (self.running) {
			self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
			self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
            [self.statusView update: self];
		}
    }
}

- (void) updateInputOverhead: (double) deltaT
{
    @synchronized(self) {
        assert(deltaT > 0);
        if(inputStartTime != 0)
            inputAddedOverhead = (uint64_t)(deltaT*1000000.0);
    }
}


@end
