//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "HardwareRunManager.h"
#import "PythonLoader.h"
#import "AppDelegate.h"
#import "EventLogger.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <mach/clock.h>
#import <stdlib.h>

// How long we keep a random light level before changing it, when not running or
// prerunning. In microseconds.
#define IDLE_LIGHT_INTERVAL 200000

@interface HardwareRunManager ()
- (void)showErrorSheet: (NSString *)message;
- (void)showErrorSheet: (NSString *)message button:(NSString *)button handler:(void (^ __nullable)(void))handler;
@end

@implementation HardwareRunManager

@synthesize outputView;
@dynamic clock;

- (int) initialPrerunCount { return 100; }
- (int) initialPrerunDelay { return 1000; }
- (NSString*) deviceID
{
	return self.device.deviceID;
}

- (NSString*) deviceName
{
	return self.device.deviceName;
}

- (NSArray *)deviceNames
{
    assert(0);
    return @[];
}

- (BOOL)switchToDeviceWithName: (NSString *)deviceName
{
    assert(0);
    return false;
}

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
        maxDelay = self.initialPrerunDelay;
		self.samplePeriodMs = 10;
	}
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // The hardware run manager is its own capturer and clock
    if (handlesInput) {
        if (self.capturer == nil) self.capturer = self;
        if (self.clock == nil) self.clock = self;
    } else {
        assert(self.inputCompanion);
        assert(self.capturer == nil);
        assert(self.clock);
        assert(self.clock == self.inputCompanion.clock);
    }
    assert(self.bConnected);
    if (handlesOutput) assert(self.outputView);
    assert(self.clock);
	self.samplePeriodMs = 10;
	[self _updatePeriod];
    [self restart];
}

- (void)showErrorSheet: (NSString *)message
{
    NSLog(@"%@", message);
    NSAlert *errorAlert = [[NSAlert alloc] init];
    errorAlert.messageText = message;
    dispatch_async(dispatch_get_main_queue(), ^{
        [errorAlert beginSheetModalForWindow:[self.outputView window] completionHandler:^(NSModalResponse returnCode) {}];
    });
}

- (void)showErrorSheet: (NSString *)message button:(NSString *)button handler:(void (^ __nullable)(void))handler
{
    NSLog(@"%@", message);
    NSAlert *errorAlert = [[NSAlert alloc] init];
    errorAlert.messageText = message;
    [errorAlert addButtonWithTitle:@"OK"];
    [errorAlert addButtonWithTitle:button];
    dispatch_async(dispatch_get_main_queue(), ^{
        [errorAlert beginSheetModalForWindow:[self.outputView window] completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertSecondButtonReturn) handler();
        }];
    });
}

// (void (^ __nullable)(NSModalResponse returnCode))handler

- (IBAction) selectionChanged: (id)sender
{
    if (!handlesInput) return;
    lastError = nil;
    NSString *selectedDevice = [self.selectionView deviceName];
    NSString *oldDevice = nil;
    if (self.device)
        oldDevice = [self.device deviceName];
    if (selectedDevice && oldDevice && [selectedDevice isEqualToString: oldDevice])
        return;
    
    self.device = nil;
    self.outputView.device = nil;
    
    if (selectedDevice == nil)
        return;
    
    [self _switchToDevice: selectedDevice];
}

- (void)_switchToDevice: (NSString *)selectedDevice
{
	assert(self.selectionView);
    [self.bConnected setState: 0];
    PythonLoader *pl = [PythonLoader sharedPythonLoader];
    uint64_t loadStartTime = [self.clock now];
    BOOL ok = [pl loadPackageNamed: selectedDevice];
    uint64_t loadDoneTime = [self.clock now];
    NSLog(@"Loading %@ Python code took %f seconds", selectedDevice, ((float)(loadDoneTime-loadStartTime)/1000000.0));
    if (!ok) {
        [self showErrorSheet: [NSString stringWithFormat:@"HardwareRunManager: Programmer error: Python module %@ cannot be imported", selectedDevice]];
        return;
    }
    
    Class deviceClass = NSClassFromString(selectedDevice);
    if (deviceClass == nil) {
        [self showErrorSheet: [NSString stringWithFormat:@"HardwareRunManager: Programmer error: class %@ does not exist", selectedDevice]];
        return;
    }
    @try {
        self.device = [[deviceClass alloc] init];
        connected = [self.device available];
    } @catch (NSException *exception) {
        [self showErrorSheet: [NSString stringWithFormat:@"Caught exception %@ while allocating hardware device class: %@", [exception name], [exception reason]]];
    }
    if (self.device == nil) {
        [self showErrorSheet: [NSString stringWithFormat:@"HardwareRunManager: cannot allocate %@ object", deviceClass]];
    }
    
    self.outputView.device = self.device;
    [self.bConnected setState: (int)connected];
    [self.selectionView.bPreRun setEnabled: connected];
    [self.statusView.bRun setEnabled: NO];
    self.preRunning = NO;
    self.running = NO;
    minInputLevel = 1.0;
    maxInputLevel = 0.0;
    inputLevel = -1;
    // This call is in completely the wrong place....
    if (connected && !alive) {
        alive = YES;
        [self performSelectorInBackground:@selector(_periodic:) withObject:self];
    }
}

- (IBAction)selectBase: (id) sender
{
	assert(self.selectionView);
    baseName = [self.selectionView baseName];
    if (baseName == nil) {
        NSLog(@"HardwareRunManager: baseName == nil");
        return;
    }
    MeasurementType *baseType;
	if (handlesInput) {
		baseType = (MeasurementType *)self.measurementType.requires;
	} else {
		baseType = (MeasurementType *)self.inputCompanion.measurementType.requires;
	}
    MeasurementDataStore *baseStore = [baseType measurementNamed: baseName];
    if (baseStore == nil) {
        [self showErrorSheet: [NSString stringWithFormat:@"HardwareRunManager: no base measurement named %@", baseName]];
        return;
    }
    if (handlesInput) {
        NSString *deviceName = baseStore.input.device;
        [self _switchToDevice:deviceName];
    } else if (handlesOutput) {
        NSString *deviceName = baseStore.output.device;
        [self _switchToDevice:deviceName];
    } else {
        assert(0);
    }
}
- (IBAction)periodChanged: (id) sender
{
	self.samplePeriodMs = [sender intValue];
	[self _updatePeriod];
}

- (void)_updatePeriod
{
	self.bSamplePeriodStepper.intValue = self.samplePeriodMs;
	self.bSamplePeriodValue.intValue = self.samplePeriodMs;
}

- (uint64_t)now
{
    return monotonicMicroSecondClock();
}

- (void)_periodic: (id)sender
{
    BOOL first = YES;
    BOOL outputLevelChanged = NO;
	uint64_t lastUpdateCall = 0;
    @try {
        while(alive) {
            BOOL nConnected = self.device && [self.device available];
            uint64_t loopTimestamp = [self.clock now];
            @synchronized(self) {
                if (newOutputValueWanted) {
                    outputTimestamp = loopTimestamp;
                    if ([self.outputCode isEqualToString: @"white"]) {
                        outputLevel = 1;
                        outputLevelChanged = YES;
                    } else if ([self.outputCode isEqualToString: @"black"]) {
                        outputLevel = 0;
                        outputLevelChanged = YES;
                    } else {
                        outputLevel = (double)rand() / (double)RAND_MAX;
                    }
                    newOutputValueWanted = NO;
                    if (VL_DEBUG) NSLog(@"HardwareRunManager: outputLevel %f at %lld", outputLevel, outputTimestamp);
                }
            }
            NSString *outputLevelStr = [NSString stringWithFormat:@"%f", outputLevel];
            if (outputLevelChanged) {
                VL_LOG_EVENT(@"hardwareOutput", loopTimestamp, outputLevelStr);
            }
            double nInputLevel = [self.device light: outputLevel];
            NSString *inputLevelStr = [NSString stringWithFormat:@"%f", inputLevel];
            if (nInputLevel != inputLevel) {
                VL_LOG_EVENT(@"hardwareInput", loopTimestamp, inputLevelStr);
            }
            if (nInputLevel < 0) {
                [self performSelectorOnMainThread:@selector(_update:) withObject:self waitUntilDone:NO];
                continue;
            }
            
            @synchronized(self) {
                if (inputLevel >= 0 && inputLevel < minInputLevel)
                    minInputLevel = inputLevel;
                if (inputLevel <= 1 && inputLevel > maxInputLevel)
                    maxInputLevel = inputLevel;
                // We call update for a number of cases:
                // - first time through the loop
                // - device connected or disconnected
                // - input level changed
                // - output level changed
                // - maxDelay has passed since last call and we are running or prerunning
                if (first
                        || nConnected != connected
                        || nInputLevel != inputLevel
                        || outputLevelChanged
                        || ((self.preRunning || self.running) && loopTimestamp > lastUpdateCall + maxDelay)
                        ) {
                    // Stopgap measure: if the device wasn't available we won't let it come available.
                    // This triggers some bug in our code...
                    if (connected)
                        connected = nConnected;
                    inputLevel = nInputLevel;
                    inputTimestamp = loopTimestamp;
                    [self performSelectorOnMainThread:@selector(_update:) withObject:self waitUntilDone:NO];
                    lastUpdateCall = loopTimestamp;
                    first = NO;
                }
                // Finally, if we are not running, we change the light level every once in a while
                if (!self.preRunning && !self.running && [self.clock now] > outputTimestamp + IDLE_LIGHT_INTERVAL)
                    newOutputValueWanted = YES;
            }
            outputLevelChanged = NO;
            double interval = (0.001 * (double)self.samplePeriodMs);
            [NSThread sleepForTimeInterval:interval];
        }
    } @catch (NSException *exception) {
		[self performSelectorOnMainThread:@selector(showErrorSheet:) withObject:[NSString stringWithFormat:@"Caught exception %@ in hardware handler: %@", [exception name], [exception reason]] waitUntilDone:NO];
    }
    alive = NO;
}

- (void)_update: (id)sender
{
    @synchronized(self) {
        NSString *inputCode = @"uncertain";
        float delta = (maxInputLevel - minInputLevel);
        if (inputLevel >= 0 && delta > 0) {
            if (inputLevel < minInputLevel + (delta / 3))
                inputCode = @"black";
            if (inputLevel > maxInputLevel - (delta / 3))
                inputCode = @"white";
        }
		// Special case for some other component handling output
		if (!handlesOutput) {
            //assert(0); //outputLight = [self.outputCompanion.outputCode isEqualToString:@"white"];
		}

        [self.bConnected setState: (connected ? NSOnState : NSOffState)];
        NSCellStateValue iVal = NSMixedState;
        if ([inputCode isEqualToString:@"black"]) {
            iVal = NSOffState;
        } else if ([inputCode isEqualToString:@"white"]) {
            iVal = NSOnState;
        }
        if (self.levelStatusView) {
            [self.levelStatusView.bInputNumericValue setDoubleValue: inputLevel];
            [self.levelStatusView.bInputNumericMinValue setDoubleValue: minInputLevel];
            [self.levelStatusView.bInputNumericMaxValue setDoubleValue: maxInputLevel];
            [self.levelStatusView.bInputValue setState: iVal];
        }
        if (handlesOutput) {
			NSCellStateValue oVal = NSMixedState;
			if ([self.outputCode isEqualToString:@"white"]) {
				oVal = NSOnState;
			} else if ([self.outputCode isEqualToString: @"black"]) {
				oVal = NSOffState;
			}
			[self.outputView.bOutputValue setState: oVal];
			if (self.running && self.outputCode && ![self.outputCode isEqualToString: oldOutputCode]) {
				// We have generated a new output code. Remember it, if we are running
				[self.collector recordTransmission: self.outputCode at:outputTimestamp];
				VL_LOG_EVENT(@"transmission", outputTimestamp, self.outputCode);
				oldOutputCode = self.outputCode;
			}
		}
        if (handlesInput) {
            // Check for detections
            if (VL_DEBUG) NSLog(@" input %@ (%f  range %f..%f) output %@", inputCode, inputLevel, minInputLevel, maxInputLevel, self.outputCode);
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
                    [self.collector recordReception:inputCode at:inputTimestamp];
					VL_LOG_EVENT(@"reception", inputTimestamp, inputCode);
                    self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
                    self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
                    [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
                    prevInputCode = self.outputCompanion.outputCode;
                    prevInputCodeDetectionCount = 0;
                    [self.outputCompanion triggerNewOutputValueAfterDelay];
                } else if (self.preRunning) {
                    [self _prerunRecordReception: inputCode];
                }

            } else {
                // We did not detect the light level we expected
                if (self.preRunning) {
                    [self _prerunRecordNoReception];
                }
            }
        }
        NSString *msg = self.device.lastErrorMessage;
        if (msg && ![msg isEqualToString:lastError]) {
            [self showErrorSheet: [NSString stringWithFormat: @"Hardware device error: %@", msg]];
            [self stop];
        }
    }
}

- (void)_prerunRecordReception: (NSString *)code
{
	prerunMoreNeeded--;
	if (VL_DEBUG) NSLog(@"prerunRecordReception %@ preRunMoreMeeded=%d\n", code, prerunMoreNeeded);
	self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prerunMoreNeeded];
	self.statusView.detectAverage = [NSString stringWithFormat: @"%.2f .. %.2f", minInputLevel, maxInputLevel];
	[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
	if (prerunMoreNeeded == 0) {
		self.outputCode = @"uncertain";
		self.statusView.detectCount = @"";
		//self.statusView.detectAverage = @"";
		[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
		[self performSelectorOnMainThread: @selector(stopPreMeasuring:) withObject: self waitUntilDone: NO];
		return;
	}
	[self.outputCompanion triggerNewOutputValue];
}

- (void) _prerunRecordNoReception
{
	assert(self.preRunning);
	// Check that we have waited long enough
	if ([self.clock now] < outputTimestamp + maxDelay)
		return;
	assert(maxDelay);
	maxDelay *= 2;
	prerunMoreNeeded = self.initialPrerunCount;
	if (VL_DEBUG) NSLog(@"prerunRecordNoReception, maxDelay is now %lld", maxDelay);
	self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prerunMoreNeeded];
	self.statusView.detectAverage = [NSString stringWithFormat: @"%.2f .. %.2f", minInputLevel, maxInputLevel];
	[self.outputCompanion triggerNewOutputValue];
}


- (void)triggerNewOutputValue
{
    if (!self.running && !self.preRunning) {
        // Idle, show intermediate value
        self.outputCode = @"uncertain";
    } else {
        if ([self.outputCode isEqualToString:@"black"]) {
            self.outputCode = @"white";
        } else {
            self.outputCode = @"black";
        }
    }
	newOutputValueWanted = YES;
    if (VL_DEBUG) NSLog(@"triggerNewOutputValue called");
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
	[self selectionChanged: self];
	[self selectBase: self];

	if (self.device == nil) {
		NSLog(@"HardwareRunManager: no hardware device available");
		return NO;
	}
	return YES;
}

- (BOOL) prepareInputDevice
{
	assert(handlesInput);
	return [self _prepareDevice];
}

- (BOOL) prepareOutputDevice
{
	assert(handlesOutput);
	return [self _prepareDevice];
}

- (void)restart
{
    @synchronized(self) {
		if (self.measurementType == nil) return;
        assert(handlesInput);
		[super restart];
		self.outputCode = @"uncertain";
		if (!alive) {
            alive = YES;
            [self performSelectorInBackground:@selector(_periodic:) withObject:self];
        }
    }
}

- (void) companionRestart
{
	[super companionRestart];
	self.outputCode = @"uncertain";
	if (!alive) {
		alive = YES;
		[self performSelectorInBackground:@selector(_periodic:) withObject:self];
	}
}

- (void)stop
{
	alive = NO;
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

- (void)setMinCaptureInterval: (uint64_t)interval
{
}


@end
