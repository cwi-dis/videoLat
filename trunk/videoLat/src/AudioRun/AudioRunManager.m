//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "AudioRunManager.h"
#import <sys/sysctl.h>

#define PRERUN_COUNT 10
#define PRERUN_INITIAL_DELAY 1000000

@implementation AudioRunManager
+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Audio Calibrate"];
    [BaseRunManager registerNib: @"AudioRunManager" forMeasurementType: @"Audio Calibrate"];
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
		maxDelay = PRERUN_INITIAL_DELAY;
		prerunMoreNeeded = PRERUN_COUNT;
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

- (void)restart
{
	@synchronized(self) {
		if (measurementType == nil) return;
		if (!self.selectionView) {
			// XXXJACK Make sure selectionView is active/visible
		}
		if (measurementType.requires == nil) {
			[self.selectionView.bBase setEnabled:NO];
			[self.selectionView.bPreRun setEnabled: YES];
		} else {
			NSArray *calibrationNames = measurementType.requires.measurementNames;
            [self.selectionView.bBase removeAllItems];
			[self.selectionView.bBase addItemsWithTitles:calibrationNames];
            if ([self.selectionView.bBase numberOfItems])
                [self.selectionView.bBase selectItemAtIndex:0];
			[self.selectionView.bBase setEnabled:YES];
            
			if ([self.selectionView.bBase selectedItem]) {
				[self.selectionView.bPreRun setEnabled: YES];
			} else {
				[self.selectionView.bPreRun setEnabled: NO];
				NSAlert *alert = [NSAlert alertWithMessageText:@"No calibrations available."
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"\"%@\" measurements should be based on a \"%@\" calibration. Please calibrate first.",
                                  measurementType.name,
                                  measurementType.requires.name
                                  ];
				[alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
			}
		}
		self.preRunning = NO;
		self.running = NO;
		[self.selectionView.bRun setEnabled: NO];
		if (self.statusView) {
			[self.statusView.bStop setEnabled: NO];
		}
	}
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
		// First check that everything is OK with base measurement and such
		if (measurementType.requires != nil) {
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
				// For all runs (calibration and non-calibration) the hardware platform should match the one in the calibration run
				if (![baseStore.machineID isEqualToString:hwName]) {
					errorMessage = [NSString stringWithFormat:@"Base measurement done on %@, current hardware is %@", baseStore.machine, hwName];
				}
				if (!measurementType.isCalibration) {
					// For non-calibration runs the input device should match the device in the calibration run
					if (![baseStore.inputDeviceID isEqualToString:self.capturer.deviceID]) {
						errorMessage = [NSString stringWithFormat:@"Base measurement uses input %@, current measurement uses %@", baseStore.inputDevice, self.capturer.deviceName];
					}
				}
				// For all runs (calibration and non-calibration) the output device should match the one in the calibration run
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
		// Do actual prerunning
		maxDelay = PRERUN_INITIAL_DELAY;
		prerunMoreNeeded = PRERUN_COUNT;
		self.preRunning = YES;
		[self.capturer startCapturing: YES];
#if 0
		// We don't trigger here, because we will very shortly get a newInputDone
		// that will trigger the output value.
		[self.outputCompanion triggerNewOutputValue];
#endif
	}
}

- (IBAction)stopPreMeasuring: (id)sender
{
	@synchronized(self) {
		self.preRunning = NO;
		[self.capturer stopCapturing];
		// We have now found PRERUN_COUNT matches in maxDelay time.
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
		[self.selectionView.bPreRun setEnabled: NO];
		[self.selectionView.bRun setEnabled: NO];
		if (!self.statusView) {
			// XXXJACK Make sure statusview is active/visible
		}
		[self.statusView.bStop setEnabled: YES];
        self.running = YES;
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
		NSLog(@"AudioRun.newOutputStart at %lld", outputStartTime);
		if (self.running) {
			[self.collector recordTransmission: @"audio" at: outputStartTime];
        }
        
    }
    return nil;
}

- (void)newOutputDone
{
    NSLog(@"AudioRun.newOutputDone at %lld", [self.clock now]);
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
			NSLog(@"newInputDone (%lld) at %lld", timestamp, [self.clock now]);
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
    if (VL_DEBUG) NSLog(@"Prerun no reception\n");
    assert(self.preRunning);
	// No data found within alotted time. Double the time, reset the count, change mirroring
	if (1 || VL_DEBUG) NSLog(@"outputStartTime=%llu, maxDelay=%llu\n", outputStartTime, maxDelay);
	maxDelay = maxDelay + (maxDelay / 4);
	prerunMoreNeeded = PRERUN_COUNT;
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
