//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "HardwareRunManager.h"
#import "AppDelegate.h"
#import "EventLogger.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <mach/clock.h>
#import <stdlib.h>

@implementation HardwareRunManager

@synthesize outputView;
@dynamic clock;

- (void)dealloc
{
}

- (int) initialPrepareCount { return 100; }
- (int) initialPrepareDelay { return 1000; }

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Hardware Calibrate"];
    [BaseRunManager registerNib: @"HardwareRun" forMeasurementType: @"Hardware Calibrate"];

    [BaseRunManager registerClass: [self class] forMeasurementType: @"Transmission Calibrate using Hardware"];
    [BaseRunManager registerNib: @"ScreenToHardwareRun" forMeasurementType: @"Transmission Calibrate using Hardware"];
    // We should also ensure that the hardware protocol is actually part of the binary
}

- (HardwareRunManager*)init
{
    self = [super init];
	if (self) {
		NSLog(@"HardwareLightProtocol = %@", @protocol(HardwareLightProtocol));
        maxDelay = self.initialPrepareDelay;
	}
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // The hardware run manager is its own capturer and clock
    if (handlesInput) {
		assert(self.capturer);
		assert(self.clock);
    } else {
        assert(self.inputCompanion);
        assert(self.capturer == nil);
        assert(self.clock);
        assert(self.clock == self.inputCompanion.clock);
    }
    if (handlesOutput) assert(self.outputView);
    assert(self.clock);
}

- (IBAction) inputSelectionChanged: (id)sender
{
	assert(handlesInput);
    assert(self.capturer);
    if (!handlesInput) return;
    NSString *selectedDevice = self.selectionView.deviceName;
    [self.capturer switchToDeviceWithName: selectedDevice];
    BOOL connected = [self.capturer available];
    assert(self.statusView);
    [self.statusView.bRun setEnabled: NO];
    [self.statusView.bPrepare setEnabled: connected];
    [self.statusView.bRun setEnabled: NO];
    self.running = NO;
    self.preparing = NO;
    self.running = NO;
}

- (void)newInputDone:(NSString *)inputCode count:(int)count at:(uint64_t)inputTimestamp
{
	assert(handlesInput);
	// Is this code the same as the previous one detected?
	if (prevInputCode && [inputCode isEqualToString: prevInputCode]) {
		prevInputCodeDetectionCount++;
		if ((prevInputCodeDetectionCount % 250) == 0) {
			showWarningAlert(@"Old code detected too often. Generating new one.");
			[self.outputCompanion triggerNewOutputValue];
		}
		return;
	}
	// Is this the code we wanted?
	if ([inputCode isEqualToString: self.outputCompanion.outputCode]) {
		if (self.running) {
			[self.collector recordReception:inputCode at:inputTimestamp];
			VL_LOG_EVENT(@"reception", inputTimestamp, inputCode);
			self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
			self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
			[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
			prevInputCode = self.outputCompanion.outputCode;
			prevInputCodeDetectionCount = 0;
			[self.outputCompanion triggerNewOutputValueAfterDelay];
		} else if (self.preparing) {
			[self _prepareRecordReception: inputCode];
		}
		return;
	}
	// We did not detect the light level we expected
	if (self.preparing) {
		[self _prepareRecordNoReception];
	}
}

- (void)_prepareRecordReception: (NSString *)code
{
	prepareMoreNeeded--;
	if (VL_DEBUG) NSLog(@"prepareRecordReception %@ prepareMoreMeeded=%d\n", code, prepareMoreNeeded);
	self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prepareMoreNeeded];
	self.statusView.detectAverage = @"";
	[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
	if (prepareMoreNeeded == 0) {
		self.outputCode = @"uncertain";
		self.statusView.detectCount = @"";
		//self.statusView.detectAverage = @"";
		[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
		[self performSelectorOnMainThread: @selector(stopPreMeasuring:) withObject: self waitUntilDone: NO];
		return;
	}
	[self.outputCompanion triggerNewOutputValue];
}

- (void) _prepareRecordNoReception
{
	assert(self.preparing);
	// Check that we have waited long enough
	if ([self.clock now] < outputTimestamp + maxDelay)
		return;
	assert(maxDelay);
	maxDelay *= 2;
	prepareMoreNeeded = self.initialPrepareCount;
	if (VL_DEBUG) NSLog(@"prepareRecordNoReception, maxDelay is now %lld", maxDelay);
	self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prepareMoreNeeded];
	self.statusView.detectAverage = @"";
	[self.outputCompanion triggerNewOutputValue];
}

- (void) _newOutputCode
{
    if (!self.running && !self.preparing) {
        // Idle, show intermediate value
        self.outputCode = @"uncertain";
    } else {
        if ([self.outputCode isEqualToString:@"black"]) {
            self.outputCode = @"white";
        } else {
            self.outputCode = @"black";
        }
    }
}

- (void)triggerNewOutputValue
{
    assert(handlesOutput);
    [self _newOutputCode];
    if (VL_DEBUG) NSLog(@"triggerNewOutputValue called");
    [self.outputView showNewData];
}

- (NSString *)getNewOutputCode
{
    return self.outputCode;
}

- (void)newOutputDone
{
    outputTimestamp = [self.clock now];
	if (self.running && self.outputCode && ![self.outputCode isEqualToString: oldOutputCode]) {
		// We have generated a new output code. Remember it, if we are running
		[self.collector recordTransmission: self.outputCode at:outputTimestamp];
		VL_LOG_EVENT(@"transmission", outputTimestamp, self.outputCode);
		oldOutputCode = self.outputCode;
	}
}

- (IBAction)stopPreMeasuring: (id)sender
{
	[super stopPreMeasuring: sender];
	self.outputCode = @"uncertain";
}

- (BOOL) _prepareDevice
{
	if (self.selectionView == nil) {
		// Not fully initialized yet
		return NO;
	}
	[self inputSelectionChanged: self];

	if (!self.capturer.available) {
		NSLog(@"HardwareRunManager: no hardware device available");
		return NO;
	}
	return YES;
}

- (BOOL) prepareInputDevice
{
	assert(handlesInput);
	return self.capturer.available;
}

- (BOOL) prepareOutputDevice
{
	assert(handlesOutput);
	return [self _prepareDevice];
}

- (void) startCapturing: (BOOL)showPreview
{
}

- (void)pauseCapturing: (BOOL)onoff
{
}

- (void) stopCapturing
{
}

- (void)stop
{
    [self.capturer stop];
}

@end
