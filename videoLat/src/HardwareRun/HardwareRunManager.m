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
        prepareMaxWaitTime = self.initialPrepareDelay;
	}
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    assert(self.clock);
    if (handlesInput) {
		assert(self.capturer);
    } else {
        assert(self.inputCompanion);
        assert(self.capturer == nil);
        assert(self.clock);
        assert(self.clock == self.inputCompanion.clock);
    }
    if (handlesOutput) assert(self.outputView);
    assert(self.clock);
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
			BOOL ok = [self.collector recordReception:inputCode at:inputTimestamp];
            if (!ok) {
                NSLog(@"Received code %@ before it was transmitted", self.outputCompanion.outputCode);
                return;
            }
			VL_LOG_EVENT(@"reception", inputTimestamp, inputCode);
			self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
			self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
			[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
			prevInputCode = self.outputCompanion.outputCode;
			prevInputCodeDetectionCount = 0;
			[self.outputCompanion triggerNewOutputValueAfterDelay];
		} else if (self.preparing) {
			[self prepareReceivedValidCode: inputCode];
		}
		return;
	}
	// We did not detect the light level we expected
	if (self.preparing) {
		[self prepareReceivedNoValidCode];
	}
}

- (void)prepareReceivedValidCode: (NSString *)code
{
    assert(handlesInput);
    assert(self.preparing);
	prepareMoreNeeded--;
	if (VL_DEBUG) NSLog(@"prepareRecordReception %@ prepareMoreMeeded=%d\n", code, prepareMoreNeeded);
	self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prepareMoreNeeded];
	self.statusView.detectAverage = @"";
	[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
	if (prepareMoreNeeded == 0) {
		self.statusView.detectCount = @"";
		self.statusView.detectAverage = @"";
		[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
		[self performSelectorOnMainThread: @selector(stopPreMeasuring:) withObject: self waitUntilDone: NO];
		return;
	}
	[self.outputCompanion triggerNewOutputValue];
}

- (void)prepareReceivedNoValidCode
{
    assert(handlesInput);
	assert(self.preparing);
	// Check that we have waited long enough
	if ([self.clock now] < outputCodeTimestamp + prepareMaxWaitTime)
		return;
    // No data found within alotted time. Double the time, reset the count, change mirroring
	assert(prepareMaxWaitTime);
	prepareMaxWaitTime *= 2;
	prepareMoreNeeded = self.initialPrepareCount;
	if (VL_DEBUG) NSLog(@"prepareRecordNoReception, maxDelay is now %lld", prepareMaxWaitTime);
	self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prepareMoreNeeded];
	self.statusView.detectAverage = @"";
    [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
	[self.outputCompanion triggerNewOutputValue];
}

- (void) _newOutputCode
{
    if (!self.running && !self.preparing) {
        // Idle, show intermediate value
        self.outputCode = @"undefined";
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
    @synchronized (self) {
        if (VL_DEBUG) NSLog(@"triggerNewOutputValue called");
        [self.outputView performSelectorOnMainThread:@selector(showNewData) withObject:nil waitUntilDone:NO ];
    }
}

- (NSString *)getNewOutputCode
{
    // Called from the redraw routine, should generate a new output code only when needed.
    @synchronized(self) {
        
        // If we are not running we should display a blue-grayish square
        if (!self.running && !self.preparing) {
            return @"undefined";
        }
        [self _newOutputCode];
        // Set outputCodeTimestamp to 0 to signal we have not reported this outputcode yet
        outputCodeTimestamp = 0;
        return self.outputCode;
    }
}

- (void)newOutputDone
{
    @synchronized(self) {
        if (outputCodeTimestamp != 0) {
            // We have already received the redraw for our mosyt recent generated code.
            // Again, redraw for some other reason, ignore.
            return;
        }
        assert(outputCodeTimestamp == 0);
        outputCodeTimestamp = [self.clock now];
        uint64_t tsOutToRemember = outputCodeTimestamp;
        if (self.running) {
            [self.collector recordTransmission: self.outputCode at: tsOutToRemember];
            VL_LOG_EVENT(@"transmission", tsOutToRemember, self.outputCode);
        }
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
    if (handlesInput) {
        [self inputSelectionChanged: self];
    } else {
        // We are output-only. go through the output handler to setup the device.
        BOOL ok = [self _selectOutputDeviceBasedOnBase];
        if (!ok) return NO;
    }

	if (!self.capturer.available) {
		NSLog(@"HardwareRunManager: no hardware device available");
		return NO;
	}
	return YES;
}

- (BOOL)_selectOutputDeviceBasedOnBase {
    assert(handlesOutput);
    assert(!handlesInput);
    assert(self.outputView);
    assert(self.selectionView);
    // Get output device driver name from base measurement
    MeasurementType *baseType = (MeasurementType *)self.inputCompanion.measurementType.requires;
    MeasurementDataStore *baseStore = [baseType measurementNamed: self.selectionView.baseName];
    if (baseStore == nil) {
        [self showErrorSheet: [NSString stringWithFormat:@"HardwareRunManager: no base measurement named %@", baseName]];
        return NO;
    }
    NSString *deviceName = baseStore.output.device;
    // Tell output driver to use this device
    BOOL ok = [self.outputView switchToDeviceWithName: deviceName];
    if (!ok) {
    	[self showErrorSheet: [NSString stringWithFormat:@"HardwareRunManager: cannot switch to output device %@", deviceName]];
	}
	return ok;
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
