//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "AudioRunManager.h"
#import <sys/sysctl.h>

@implementation AudioRunManager

- (int) initialPrerunCount { return 10; }
- (int) initialPrerunDelay { return 1000000; }

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Audio Roundtrip"];
    [BaseRunManager registerNib: @"AudioRunManager" forMeasurementType: @"Audio Roundtrip"];
}


- (void)dealloc
{
    // Deallocate the capturer first
    self.capturer = nil;
	self.clock = nil;
}


- (AudioRunManager*)init
{
    self = [super init];
	if (self) {
		outputStartTime = 0;
		outputActive = NO;
		foundCurrentSample = NO;
		triggerOutputWhenDone = NO;
		maxDelay = 0;
		prerunMoreNeeded = 0;
	}
    return self;
}

- (void)awakeFromNib
{
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
    self.statusView = self.measurementMaster.statusView;
    self.collector = self.measurementMaster.collector;
//    if (self.clock == nil) self.clock = self;
    [self restart];
}

#if 0
- (uint64_t)now
{
    UInt64 machTimestamp = mach_absolute_time();
    Nanoseconds nanoTimestamp = AbsoluteToNanoseconds(*(AbsoluteTime*)&machTimestamp);
    uint64_t timestamp = *(UInt64 *)&nanoTimestamp;
    timestamp = timestamp / 1000;
    return timestamp;
}
#endif

- (void)stop
{
	if (self.capturer) [self.capturer stop];
	if (self.outputView) [self.outputView stop];
	self.capturer = nil;
	self.outputView = nil;
}

- (IBAction)startPreMeasuring: (id)sender
{
	@synchronized(self) {
        assert(handlesInput);
		// First check that everything is OK with base measurement and such
		if (self.measurementType.requires != nil) {
			// First check that a base measurement has been selected.
			NSString *errorMessage;
			NSMenuItem *baseItem = [self.selectionView.bBase selectedItem];
			NSString *baseName = [baseItem title];
			MeasurementType *baseType = self.measurementType.requires;
			MeasurementDataStore *baseStore = [baseType measurementNamed: baseName];
			if (baseType == nil) {
				errorMessage = @"No base (calibration) measurement selected.";
			} else {
				// Check that the base measurement is compatible with this measurement,
				char hwName_c[100] = "unknown";
				size_t len = sizeof(hwName_c);
				sysctlbyname("hw.model", hwName_c, &len, NULL, 0);
				NSString *hwName = [NSString stringWithUTF8String:hwName_c];
				// For all runs (calibration and non-calibration) the hardware platform should match the one in the calibration run
                if (handlesOutput && ![baseStore.output.machineTypeID isEqualToString:hwName]) {
                    errorMessage = [NSString stringWithFormat:@"Base measurement output done on %@, current hardware is %@", baseStore.output.machineTypeID, hwName];
                }
                if (handlesInput && ![baseStore.input.machineTypeID isEqualToString:hwName]) {
                    errorMessage = [NSString stringWithFormat:@"Base measurement input done on %@, current hardware is %@", baseStore.input.machineTypeID, hwName];
                }
                // Check that input device matches (except for output-only calibrations)
                if (!baseType.outputOnlyCalibration && ![baseStore.input.deviceID isEqualToString:self.capturer.deviceID]) {
                    errorMessage = [NSString stringWithFormat:@"Base measurement uses input %@, current measurement uses %@", baseStore.input.device, self.capturer.deviceName];
                }
				// Check that output device matches (except for input-only calibrations)
				if (!baseType.inputOnlyCalibration && ![baseStore.output.deviceID isEqualToString:self.outputView.deviceID]) {
					errorMessage = [NSString stringWithFormat:@"Base measurement uses output %@, current measurement uses %@", baseStore.output.device, self.outputView.deviceName];
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
        if (!handlesOutput) {
            BOOL ok = [self.outputCompanion companionStartPreMeasuring];
            if (!ok) return;
        }
		// Do actual prerunning
		maxDelay = self.initialPrerunDelay;
		prerunMoreNeeded = self.initialPrerunCount;
		self.preRunning = YES;
		[self.capturer startCapturing: YES];
	}
}

- (IBAction)stopPreMeasuring: (id)sender
{
	@synchronized(self) {
		self.preRunning = NO;
        if (!handlesOutput)
            [self.outputCompanion companionStopPreMeasuring];
		[self.capturer stopCapturing];
		// We have now found enough matches in maxDelay time.
		// Assume that 4*maxDelay is a decent upper bound for detection.
		maxDelay = maxDelay*4;
		[self.selectionView.bPreRun setEnabled: NO];
		[self.selectionView.bRun setEnabled: YES];
		if (!self.statusView) {
			// XXXJACK Make sure statusview is active/visible
		}
		[self.statusView.bStop setEnabled: NO];
	}
}

- (IBAction)startMeasuring: (id)sender
{
    @synchronized(self) {
        assert(handlesInput);
		[self.selectionView.bPreRun setEnabled: NO];
		[self.selectionView.bRun setEnabled: NO];
		if (!self.statusView) {
			// XXXJACK Make sure statusview is active/visible
		}
		[self.statusView.bStop setEnabled: YES];
        self.running = YES;
        if (!handlesOutput)
            [self.outputCompanion companionStartMeasuring];
        [self.capturer startCapturing: NO];
        [self.collector startCollecting: self.measurementType.name input: self.capturer.deviceID name: self.capturer.deviceName output: self.outputView.deviceID name: self.outputView.deviceName];
        [self.outputCompanion triggerNewOutputValue];
    }
}

- (void)triggerNewOutputValue
{
	if (outputActive) {
		// We cannot start a new output when one is active. Remember for later
		triggerOutputWhenDone = YES;
		return;
	}
	triggerOutputWhenDone = NO;
	[self.outputView performSelectorOnMainThread:@selector(showNewData) withObject:nil waitUntilDone:NO ];
}

- (CIImage *)newOutputStart
{
	assert(!outputActive);
	outputActive = YES;
	foundCurrentSample = NO;
    if ((self.running || self.preRunning)) {
        outputStartTime = [self.clock now];
		if (VL_DEBUG) NSLog(@"AudioRun.newOutputStart at %lld", outputStartTime);
		if (self.running) {
			[self.collector recordTransmission: @"audio" at: outputStartTime];
        }
        
    }
    return nil;
}

- (void)newOutputDone
{
    if (VL_DEBUG) NSLog(@"AudioRun.newOutputDone at %lld", [self.clock now]);
	assert(outputActive);
	outputActive = NO;
	if (triggerOutputWhenDone)
		[self triggerNewOutputValue];
}

- (void) newInputDone: (void*)buffer size: (int)size channels: (int)channels at: (uint64_t)timestamp
{
    @synchronized(self) {
		// See whether we detect the pattern we are looking for, and report to user.
		BOOL foundSample = [self.processor feedData:buffer size:size channels:channels at:timestamp];
		[self.bDetection setState: (foundSample? NSOnState : NSOffState)];

		// If we're not running or prerunning we're done.
		if (!self.running && !self.preRunning)
			return;

		// If we have already reported a match there's nothing more to do
		if (foundCurrentSample)
			return;
			
		// Process whether we found a sample (or not)
        if (foundSample) {
			if (VL_DEBUG) NSLog(@"newInputDone (%lld) at %lld", timestamp, [self.clock now]);
			foundCurrentSample = YES;
            if (self.running) {
                [self.collector recordReception: @"audio" at: [self.processor lastMatchTimestamp]];
            } else if (self.preRunning) {
                [self _prerunRecordReception: self.outputCompanion.outputCode];
            }
            [self.outputCompanion triggerNewOutputValue];
        } else {
			// Nothing found. See whether we are still expecting something
			if ([self.clock now] - outputStartTime > maxDelay) {
				// No we are not. Admit failure, and do another sample.
				if (self.preRunning) {
					[self _prerunRecordNoReception];
				} else {
					[self.collector recordReception: @"noaudio" at: [self.clock now]];
				}
				[self.outputCompanion triggerNewOutputValue];
			}
        }

		// Update status display, if we are running
		if (self.running) {
			self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
			self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
            [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
		}
    }
}

- (void) _prerunRecordNoReception
{
	assert(handlesInput);
    if (VL_DEBUG) NSLog(@"Prerun no reception\n");
    assert(self.preRunning);
	// No data found within alotted time. Double the time, reset the count, change mirroring
	if (1 || VL_DEBUG) NSLog(@"outputStartTime=%llu, maxDelay=%llu\n", outputStartTime, maxDelay);
	maxDelay = maxDelay + (maxDelay / 4);
	prerunMoreNeeded = self.initialPrerunCount;
	self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prerunMoreNeeded];
	self.statusView.detectAverage = @"";
	[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
}

- (void) _prerunRecordReception: (NSString *)code
{
    if (1 || VL_DEBUG) NSLog(@"prerun reception %@\n", code);
    assert(self.preRunning);
    if (self.preRunning) {
	
        prerunMoreNeeded -= 1; // And we need one less
		
        self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prerunMoreNeeded];
		self.statusView.detectAverage = @"";
        [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
        if (1 || VL_DEBUG) NSLog(@"preRunMoreMeeded=%d\n", prerunMoreNeeded);
		
        if (prerunMoreNeeded == 0) {
            self.statusView.detectCount = @"";
			self.statusView.detectAverage = @"";
            [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
            [self performSelectorOnMainThread: @selector(stopPreMeasuring:) withObject: self waitUntilDone: NO];
        }
    }
}
@end
