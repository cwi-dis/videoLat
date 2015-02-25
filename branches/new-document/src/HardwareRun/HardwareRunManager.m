//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "HardwareRunManager.h"
#import "PythonLoader.h"
#import "appDelegate.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <mach/clock.h>
#import <stdlib.h>

// How long we keep a random light level before changing it, when not running or
// prerunning. In microseconds.
#define IDLE_LIGHT_INTERVAL 200000

@implementation HardwareRunManager

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

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Hardware Calibrate"];
    [BaseRunManager registerNib: @"HardwareRunManager" forMeasurementType: @"Hardware Calibrate"];

    [BaseRunManager registerClass: [self class] forMeasurementType: @"Screen Output Calibrate"];
    [BaseRunManager registerNib: @"ScreenToHardwareRunManager" forMeasurementType: @"Screen Output Calibrate"];
    // We should also ensure that the hardware protocol is actually part of the binary
    Protocol *hlp = @protocol(HardwareLightProtocol);
    if (VL_DEBUG) NSLog(@"HardwareLightProtocol = %@", hlp);
}

- (HardwareRunManager*)init
{
    self = [super init];
	if (self) {
        maxDelay = self.initialPrerunDelay;
	}
    return self;
}

- (void)awakeFromNib
{
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];

    if (self.clock == nil) self.clock = self;
	if (self.capturer == nil) self.capturer = self;
    [self restart];
}

- (IBAction) deviceChanged: (id)sender
{
    if (!handlesInput) return;
    lastError = nil;
    if (self.selectionView.bDevices == nil)
        return;
    if ([self.selectionView.bDevices indexOfSelectedItem] == 0)
        return;
    NSString *selectedDevice = [self.selectionView.bDevices titleOfSelectedItem];
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
    BOOL ok = [pl loadPackageNamed: selectedDevice];
    if (!ok) {
        NSLog(@"HardwareRunManager: Programmer error: Python module %@ cannot be imported", selectedDevice);
        return;
    }
    
    Class deviceClass = NSClassFromString(selectedDevice);
    if (deviceClass == nil) {
        NSLog(@"HardwareRunManager: Programmer error: class %@ does not exist", selectedDevice);
        return;
    }
    self.device = [[deviceClass alloc] init];
    if (self.device == nil) {
        NSLog(@"HardwareRunManager: cannot allocate %@ object", deviceClass);
    }
    
    self.outputView.device = self.device;
    connected = [self.device available];
    [self.bConnected setState: (int)connected];
    [self.selectionView.bPreRun setEnabled: connected];
    [self.selectionView.bRun setEnabled: NO];
    self.preRunning = NO;
    self.running = NO;
    minInputLevel = 1.0;
    maxInputLevel = 0.0;
    inputLevel = -1;
    // This call is in completely the wrong place....
    if (!alive) {
        alive = YES;
        [self performSelectorInBackground:@selector(_periodic:) withObject:self];
    }
}

- (IBAction)selectBase: (id) sender
{
	assert(self.selectionView);
    if (self.selectionView.bBase == nil) {
        NSLog(@"HardwareRunManager: bBase == nil");
        return;
    }
    NSMenuItem *baseItem = [self.selectionView.bBase selectedItem];
    NSString *baseName = [baseItem title];
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
        NSLog(@"HardwareRunManager: no base measurement named %@", baseName);
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

- (uint64_t)now
{
    UInt64 machTimestamp = mach_absolute_time();
    Nanoseconds nanoTimestamp = AbsoluteToNanoseconds(*(AbsoluteTime*)&machTimestamp);
    uint64_t timestamp = *(UInt64 *)&nanoTimestamp;
    timestamp = timestamp / 1000;
    return timestamp;
}

- (void)_periodic: (id)sender
{
    BOOL first = YES;
    BOOL outputLevelChanged = NO;
	uint64_t lastUpdateCall = 0;
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
        double nInputLevel = [self.device light: outputLevel];
        if (nInputLevel < 0) {
            [self performSelectorOnMainThread:@selector(_update:) withObject:self waitUntilDone:NO];
            continue;
        }
        
        @synchronized(self) {
#ifdef IGNORE_LEVELS_0_AND_1
			if (inputLevel > 0 && inputLevel < minInputLevel)
				minInputLevel = inputLevel;
			if (inputLevel < 1 && inputLevel > maxInputLevel)
				maxInputLevel = inputLevel;
#else
			if (inputLevel >= 0 && inputLevel < minInputLevel)
				minInputLevel = inputLevel;
			if (inputLevel <= 1 && inputLevel > maxInputLevel)
				maxInputLevel = inputLevel;

#endif
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
        [NSThread sleepForTimeInterval:0.001];
    }
}

- (void)_update: (id)sender
{
    @synchronized(self) {
        NSString *inputCode = @"mixed";
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
        [self.bInputNumericValue setDoubleValue: inputLevel];
        [self.bInputNumericMinValue setDoubleValue: minInputLevel];
        [self.bInputNumericMaxValue setDoubleValue: maxInputLevel];
        NSCellStateValue iVal = NSMixedState;
        if ([inputCode isEqualToString:@"black"]) {
            iVal = NSOffState;
        } else if ([inputCode isEqualToString:@"white"]) {
            iVal = NSOnState;
        }
        [self.bInputValue setState: iVal];
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
				oldOutputCode = self.outputCode;
			}
		}
        if (handlesInput) {
            // Check for detections
            if (1 || VL_DEBUG) NSLog(@" input %@ (%f  range %f..%f) output %@", inputCode, inputLevel, minInputLevel, maxInputLevel, self.outputCode);
            if ([inputCode isEqualToString: self.outputCompanion.outputCode]) {
                if (self.running) {
                    [self.collector recordReception:inputCode at:inputTimestamp];
                    self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
                    self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
                    [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
                    [self.outputCompanion triggerNewOutputValue];
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
            lastError = msg;
            NSAlert *alert = [NSAlert alertWithMessageText:@"Hardware device error" defaultButton:@"Continue" alternateButton:@"Stop" otherButton:nil informativeTextWithFormat:@"%@", msg];
            if ([alert runModal] == NSAlertAlternateReturn)
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
		self.outputCode = @"mixed";
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
        self.outputCode = @"mixed";
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

#if 0
- (IBAction)startPreMeasuring: (id)sender
{
	@synchronized(self) {
        assert(handlesInput);
        // XXXX No need to check base measuremen??
        [self.bPreRun setEnabled: NO];
        [self.bRun setEnabled: NO];
        if (self.statusView) {
            [self.statusView.bStop setEnabled: NO];
        }
        // Do actual prerunning
        prerunMoreNeeded = self.initialPrerunCount;
        if (!handlesOutput) {
            BOOL ok = [self.outputCompanion companionStartPreMeasuring];
            if (!ok) return;
        }
        self.preRunning = YES;
        [self.outputCompanion triggerNewOutputValue];
    }
}
#endif

- (IBAction)stopPreMeasuring: (id)sender
{
#if 1
	[super stopPreMeasuring: sender];
	self.outputCode = @"mixed";
#else
	@synchronized(self) {
		self.preRunning = NO;
        if (!handlesOutput)
            [self.outputCompanion companionStopPreMeasuring];
        outputLevel = 0.5;
        newOutputValueWanted = NO;
		[self.bPreRun setEnabled: NO];
		[self.bRun setEnabled: YES];
		if (!self.statusView) {
			// XXXJACK Make sure statusview is active/visible
		}
		[self.statusView.bStop setEnabled: NO];
	}
#endif
}

#if 0
- (IBAction)startMeasuring: (id)sender
{
    @synchronized(self) {
		[self.bPreRun setEnabled: NO];
		[self.bRun setEnabled: NO];
		if (!self.statusView) {
			// XXXJACK Make sure statusview is active/visible
		}
		[self.statusView.bStop setEnabled: YES];
        self.running = YES;
        if (!handlesOutput)
            [self.outputCompanion companionStartMeasuring];
        [self.collector startCollecting: self.measurementType.name input: self.device.deviceID name: self.device.deviceName output: self.device.deviceID name: self.device.deviceName];
        [self.outputCompanion triggerNewOutputValue];
    }
}
#endif

- (BOOL) _prepareDevice
{
	if (self.selectionView.bDevices == nil && self.selectionView.bBase == nil) {
		// Not fully initialized yet
		return NO;
	}
	[self deviceChanged: self];
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
		self.outputCode = @"mixed";
		if (!alive) {
            alive = YES;
            [self performSelectorInBackground:@selector(_periodic:) withObject:self];
        }
    }
}

- (void) companionRestart
{
	[super companionRestart];
	self.outputCode = @"mixed";
	if (!alive) {
		alive = YES;
		[self performSelectorInBackground:@selector(_periodic:) withObject:self];
	}
}

- (void)stop
{
	alive = NO;
}

- (CIImage *)newOutputStart
{
	[NSException raise:@"HardwareRunManager" format:@"Must override newOutputStart in subclass"];
	return nil;
}

- (void)newOutputDone
{
	[NSException raise:@"HardwareRunManager" format:@"Must override newOutputDone in subclass"];
}

- (void)setFinderRect: (NSRect)theRect
{
	[NSException raise:@"HardwareRunManager" format:@"Must override setFinderRect in subclass"];
}


- (void)newInputStart
{
	[NSException raise:@"HardwareRunManager" format:@"Must override newInputStart in subclass"];
}

- (void)newInputStart: (uint64_t)timestamp
{
	[NSException raise:@"HardwareRunManager" format:@"Must override newInputStart: in subclass"];
}


- (void)newInputDone
{
	[NSException raise:@"HardwareRunManager" format:@"Must override newInputDone in subclass"];
}


- (void) newInputDone: (void*)buffer
                width: (int)w
               height: (int)h
               format: (const char*)formatStr
                 size: (int)size
{
	[NSException raise:@"HardwareRunManager" format:@"Must override newInputDone in subclass"];
}

- (void) startCapturing: (BOOL)showPreview
{
}

- (void) stopCapturing
{
}

@end
