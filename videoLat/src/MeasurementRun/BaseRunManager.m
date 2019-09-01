//
//  BaseRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "BaseRunManager.h"
#import "MachineDescription.h"
#import "AppDelegate.h"
#import "EventLogger.h"
#import "NetworkIODevice.h"

static NSMutableDictionary *runManagerClasses;
static NSMutableDictionary *runManagerNibs;
#ifdef WITH_UIKIT
static NSMutableDictionary *runManagerSelectionNibs;
#endif
@implementation BaseRunManager
@synthesize clock;
@synthesize running;
@synthesize preparing;
@synthesize prevOutputCode;

- (int) initialPrepareCount
{
	[NSException raise:@"BaseRunManager" format:@"Must override initialPrepareCount in subclass %@", [self class]];
	return 1;
}

- (int) initialPrepareDelay
{
	[NSException raise:@"BaseRunManager" format:@"Must override initialPrepareDelay in subclass %@", [self class]];
	return 1;
}


+ (void)initialize
{
    runManagerClasses = [[NSMutableDictionary alloc] initWithCapacity:10];
    runManagerNibs = [[NSMutableDictionary alloc] initWithCapacity:10];
#ifdef WITH_UIKIT
    runManagerSelectionNibs = [[NSMutableDictionary alloc] initWithCapacity:10];
#endif
}

+ (void)registerClass: (Class)managerClass forMeasurementType: (NSString *)name
{
    // XXXJACK assert it is a subclass of BaseRunManager
    Class oldClass = [runManagerClasses objectForKey:name];
    if (oldClass != nil && oldClass != managerClass) {
        NSLog(@"BaseRunManager: attempt to set class for %@ to %@ but it was already set to %@\n", name, managerClass, oldClass);
        abort();
    }
    if (VL_DEBUG) NSLog(@"BaseRunManager: Register %@ for %@\n", managerClass, name);
    [runManagerClasses setObject:managerClass forKey:name];
}

+ (Class)classForMeasurementType: (NSString *)name
{
    return [runManagerClasses objectForKey:name];
}

+ (void)registerNib: (NSString*)nibName forMeasurementType: (NSString *)name
{
    NSString *oldNib = [runManagerNibs objectForKey:name];
    if (oldNib != nil && oldNib != nibName) {
        NSLog(@"BaseRunManager: attempt to set Nib for %@ to %@ but it was already set to %@\n", name, nibName, oldNib);
        abort();
    }
    if (VL_DEBUG) NSLog(@"BaseRunManager: Register %@ for %@\n", nibName, name);
    [runManagerNibs setObject:nibName forKey:name];
}

+ (NSString *)nibForMeasurementType: (NSString *)name
{
    return [runManagerNibs objectForKey:name];
}

#ifdef WITH_UIKIT
+ (void)registerSelectionNib: (NSString*)nibName forMeasurementType: (NSString *)name
{
    NSString *oldNib = [runManagerSelectionNibs objectForKey:name];
    if (oldNib != nil && oldNib != nibName) {
        NSLog(@"BaseRunManager: attempt to set Nib for %@ to %@ but it was already set to %@\n", name, nibName, oldNib);
        abort();
    }
    if (VL_DEBUG) NSLog(@"BaseRunManager: Register selection nib%@ for %@\n", nibName, name);
    [runManagerSelectionNibs setObject:nibName forKey:name];
}

+ (NSString *)selectionNibForMeasurementType: (NSString *)name
{
    return [runManagerSelectionNibs objectForKey:name];
}
#endif

@synthesize measurementType;

- (BaseRunManager *) init
{
    self = [super init];
    if (self) {
        networkHelper = NO;
    }
    return self;
}

- (void)terminate
{
	self.collector = nil;
	self.statusView = nil;
	self.measurementMaster = nil;
	
}

- (void) dealloc
{
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    assert(self.clock);
#ifdef WITH_APPKIT
    assert(self.selectionView);
    assert(self.measurementMaster);
#endif
    assert(self.capturer);
    assert(self.statusView);
    assert(self.outputView);
    if (!networkHelper) {
        assert(self.collector);
    }
    // xxxjack this needs to be done differently, based on a subclass
    if (self.networkIODevice && self.networkIODevice == self.capturer) {
        networkServer = YES;
    }
    if (networkServer) {
        assert(self.networkIODevice);
        [self.networkIODevice openServer];
    }
        
}

- (void) selectMeasurementType:(NSString *)typeName
{
	self.measurementType = [MeasurementType forType:typeName];
    [self restart];
}

#ifdef WITH_UIKIT
- (void)runForType: (NSString *)measurementTypeName withBase: (NSString *)baseMeasurementName
{
	baseName = baseMeasurementName;
	[self selectMeasurementType:measurementTypeName];
	if (!networkHelper)
		[self startPreMeasuring:self];
}
#endif

#ifdef WITH_APPKIT
- (IBAction) inputSelectionChanged: (id)sender
{
    assert(self.capturer);
    assert(self.selectionView);
    assert(self.statusView);
    [self restart];
}
#endif

- (IBAction)startPreMeasuring: (id)sender
{
	@synchronized(self) {
 		assert(!self.preparing);
		assert(!self.running);
        assert(self.capturer);
        assert(self.outputView);
        // First check that everything is OK with base measurement and such
		if (self.measurementType.requires != nil) {
			// First check that a base measurement has been selected.
			NSString *errorMessage;
            assert(self.selectionView);
            baseName = self.selectionView.baseName;
            if (baseName == nil) {
                NSLog(@"BaseRunManager: baseName == nil");
                return;
            }
			MeasurementType *baseType = self.measurementType.requires;
			MeasurementDataStore *baseStore = [baseType measurementNamed: baseName];
			if (baseType == nil) {
				errorMessage = @"No base (calibration) measurement selected.";
			} else {
                BOOL inputDeviceShouldMatch = !self.measurementType.inputOnlyCalibration;
                BOOL outputDeviceShouldMatch = !self.measurementType.outputOnlyCalibration;
                // We relax the requirements if we're network-based
                if (self.networkIODevice) {
                    if (self.networkIODevice == self.capturer) {
                        // We are using networked input.
                        inputDeviceShouldMatch = false;
                    } else {
                        // Assume we are using networked output.
                        outputDeviceShouldMatch = false;
                    }
                }

				// Check that the base measurement is compatible with this measurement,
				NSString *hwName = [[MachineDescription thisMachine] machineTypeID];
				// For all runs that are not single-ended clibrations the hardware platform should match the one in the calibration run
                if (outputDeviceShouldMatch && ![baseStore.output.machineTypeID isEqualToString:hwName]) {
                    errorMessage = [NSString stringWithFormat:@"Current machine is %@, Output base measurement done on %@", hwName, baseStore.output.machineTypeID];
                }
                if (inputDeviceShouldMatch && ![baseStore.input.machineTypeID isEqualToString:hwName]) {
                    errorMessage = [NSString stringWithFormat:@"Current machine is %@, input base measurement done on %@", hwName, baseStore.input.machineTypeID];
                }
                // For runs where we are responsible for input the input device should match
                if (inputDeviceShouldMatch && ![baseStore.input.deviceID isEqualToString:self.capturer.deviceID]) {
                    errorMessage = [NSString stringWithFormat:@"Input %@ selected, base measurement done with %@", self.capturer.deviceName, baseStore.input.device];
                }
				// For runs where we are responsible for output the output device should match
                if (outputDeviceShouldMatch && ![baseStore.output.deviceID isEqualToString:self.outputView.deviceID]) {
					errorMessage = [NSString stringWithFormat:@"Output %@ selected, base measurement done with %@", self.outputView.deviceName, baseStore.output.device];
				}
			}
			if (errorMessage) {
				showWarningAlert(errorMessage);
			}
			[self.collector.dataStore useCalibration:baseStore];
				
		}
		if (self.statusView) {
#ifdef WITH_APPKIT
            [self.statusView.bPrepare setEnabled: NO];
#endif
			[self.statusView.bRun setEnabled: NO];
			[self.statusView.bStop setEnabled: NO];
		}
        // Do actual prerunning
        prepareMaxWaitTime = self.initialPrepareDelay; // Start with 1ms delay (ridiculously low)
        prepareMoreNeeded = self.initialPrepareCount;
        self.preparing = YES;
		VL_LOG_EVENT(@"startPremeasuring", 0LL, @"");
		[self.capturer startCapturing: YES];
		[self triggerNewOutputValue];
#if 0
        if (self.networkIODevice) {
            [self.networkIODevice reportStatus: @"Determining RTT"];
        }
#endif
	}
}

- (IBAction)stopPreMeasuring: (id)sender
{
	@synchronized(self) {
		assert(self.preparing);
		assert(!self.running);
		self.preparing = NO;
		// We now have a ballpark figure for the maximum delay. Use 4 times that as the highest
		// we are willing to wait for.
		prepareMaxWaitTime = prepareMaxWaitTime * 4;
		[self.capturer stopCapturing];
		assert (self.statusView);
#ifdef WITH_APPKIT
        [self.statusView.bPrepare setEnabled: NO];
#endif
		[self.statusView.bStop setEnabled: NO];
        // See whether we have received enough information for the measurement to start if we
        // have a remote companion
        if (self.networkIODevice) {
            bool ok = [self prepareMeasurementFromRemoteData];
            if (!ok) return;
        }
        
        [self.statusView.bRun setEnabled: YES];
		VL_LOG_EVENT(@"stopPremeasuring", 0LL, @"");
        self.outputCode = @"uncertain";
	}
}

- (BOOL)prepareMeasurementFromRemoteData
{
    NSString *errorMessage = nil;
    MeasurementDataStore *baseStore = nil;
    if (!self.measurementType.isCalibration) {
        // If this is not a calibration we should check our base type
        assert(self.selectionView);
        baseName = self.selectionView.baseName;
        MeasurementType *baseType = self.measurementType.requires;
        baseStore = [baseType measurementNamed: baseName];
        if (baseType == nil) {
            errorMessage = @"No base (calibration) measurement selected.";
        } else if (baseStore == nil) {
            
        } else {
            // Check that the base measurement is compatible with this measurement,
            NSString *hwName = [[MachineDescription thisMachine] machineTypeID];
            // The hardware platform should match the one in the calibration run
            if (![baseStore.output.machineTypeID isEqualToString:hwName]) {
                errorMessage = [NSString stringWithFormat:@"Base measurement output done on %@, current hardware is %@", baseStore.output.machine, hwName];
            }
            assert(self.outputView);
            // For runs where we are responsible for output the output device should match
            if (![baseStore.output.deviceID isEqualToString:self.outputView.deviceID]) {
                errorMessage = [NSString stringWithFormat:@"Base measurement uses output %@, current measurement uses %@", baseStore.output.device, self.outputView.deviceName];
            }
        }
    }
    DeviceDescription *remoteInputDeviceDescription = [self.networkIODevice remoteInputDeviceDescription];
    DeviceDescription *remoteOutputDeviceDescription = [self.networkIODevice remoteOutputDeviceDescription];
    if (errorMessage == nil && remoteInputDeviceDescription == nil && remoteOutputDeviceDescription) {
        errorMessage = @"No device description received from remote helper.";
    }
    if (errorMessage) {
        [self.networkIODevice reportStatus: @"Missing calibration"];
        showWarningAlert(errorMessage);
        return NO;
    }
    // Remember the input and output device in the collector
    if (baseStore) {
        [self.collector.dataStore useOutputCalibration:baseStore];
    } else {
        self.collector.dataStore.output = [[DeviceDescription alloc] initFromOutputDevice: self.outputView];
    }
    if (remoteInputDeviceDescription) self.collector.dataStore.input = remoteInputDeviceDescription;
    if (remoteOutputDeviceDescription) self.collector.dataStore.output = remoteOutputDeviceDescription;

    [self.networkIODevice reportStatus: @"Ready to run"];
    return YES;
}


- (void)reportResultsToRemote: (MeasurementDataStore *)mr
{
    mr.measurementType = self.measurementType.name;
    if (self.capturer) [self.capturer stop];
    if (self.completionHandler) {
        [self.completionHandler performSelectorOnMainThread:@selector(openUntitledDocumentWithMeasurement:) withObject:mr waitUntilDone:NO];
    } else {
#ifdef WITH_APPKIT
        AppDelegate *d = (AppDelegate *)[[NSApplication sharedApplication] delegate];
        [d performSelectorOnMainThread:@selector(openUntitledDocumentWithMeasurement:) withObject:mr waitUntilDone:NO];
        [self.statusView.window close];
#else
        assert(0);
#endif
    }
}

- (BOOL)reportInputDeviceToRemote
{
    DeviceDescription *deviceDescriptorToSend = nil;
    if (self.measurementType.isCalibration) {
#ifdef WITH_APPKIT
        if (self.selectionView) assert(self.selectionView.bBase == nil);
#endif
        assert(self.capturer);
        deviceDescriptorToSend = [[DeviceDescription alloc] initFromInputDevice: self.capturer];
    } else {
        assert(self.selectionView);
        baseName = self.selectionView.baseName;
        if (baseName == nil) {
            NSLog(@"NetworkRunManager: baseName == nil");
            return NO;
        }
        MeasurementType *baseType;
        baseType = (MeasurementType *)self.measurementType.requires;
        MeasurementDataStore *baseStore = [baseType measurementNamed: baseName];
        assert(baseStore.input);
        deviceDescriptorToSend = [[DeviceDescription alloc] initFromCalibrationInput: baseStore];
    }
    [self.networkIODevice reportInputDevice: deviceDescriptorToSend];
    return YES;
}

- (BOOL)reportOutputDeviceToRemote
{
    DeviceDescription *deviceDescriptorToSend = nil;
    if (self.measurementType.isCalibration) {
        assert(self.outputView);
        deviceDescriptorToSend = [[DeviceDescription alloc] initFromOutputDevice: self.outputView];
    } else {
        assert(self.selectionView);
        baseName = self.selectionView.baseName;
        if (baseName == nil) {
            NSLog(@"NetworkRunManager: baseName == nil");
            return NO;
        }
        MeasurementType *baseType;
        baseType = (MeasurementType *)self.measurementType.requires;
        MeasurementDataStore *baseStore = [baseType measurementNamed: baseName];
        assert(baseStore.output);
        deviceDescriptorToSend = [[DeviceDescription alloc] initFromCalibrationOutput: baseStore];
    }
    [self.networkIODevice reportOutputDevice: deviceDescriptorToSend];
    return YES;
}

- (IBAction)startMeasuring: (id)sender
{
    @synchronized(self) {
		assert(!self.preparing);
		assert(!self.running);
		assert(self.measurementType.name);
		assert(self.capturer.deviceID);
		assert(self.capturer.deviceName);
		assert(self.outputView.deviceID);
		assert(self.outputView.deviceName);
		assert(self.statusView);
#ifdef WITH_APPKIT
        [self.statusView.bPrepare setEnabled: NO];
#endif
		[self.statusView.bRun setEnabled: NO];
		[self.statusView.bStop setEnabled: YES];
        self.running = YES;
		VL_LOG_EVENT(@"startMeasuring", 0LL, @"");
        [self.capturer startCapturing: NO];
        [self.collector startCollecting: self.measurementType.name input: self.capturer.deviceID name: self.capturer.deviceName output: self.outputView.deviceID name: self.outputView.deviceName];
        [self triggerNewOutputValue];
        if (self.networkIODevice) {
            [self.networkIODevice reportStatus: @"Running measurements"];
        }
    }
}

#ifdef WITH_APPKIT

- (void)showErrorSheet: (NSString *)message
{
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(showErrorSheet:) withObject:message waitUntilDone:NO];
		return;
	}
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
#endif

- (BOOL) prepareInputDevice
{
    BOOL ok = self.capturer.available;
    if (!ok) return NO;
    if (self.networkIODevice && self.networkIODevice != self.capturer) {
        // Only do this for helper input devices....
        ok = [self reportInputDeviceToRemote];
        if (!ok) return NO;
        if (networkHelper) {
            [self.capturer startCapturing:YES];
        }
    }
    return YES;
}

- (BOOL) prepareOutputDevice
{
    assert(self.outputView);
    BOOL ok = self.outputView.available;
    if (!ok) return NO;
    if (self.networkIODevice && self.networkIODevice == self.capturer) {
        // Only do this for helper output devices....
        ok = [self reportOutputDeviceToRemote];
    }
    return ok;
}

- (void)restart
{
    assert(self.selectionView);
    assert (self.statusView);
	@synchronized(self) {
#ifdef WITH_APPKIT
        [self.statusView.bPrepare setEnabled: NO];
#endif
        [self.statusView.bRun setEnabled: NO];
        [self.statusView.bStop setEnabled: NO];
        self.preparing = NO;
        self.running = NO;
        self.outputCode = @"uncertain";
        
        if (self.measurementType == nil) {
            NSLog(@"Error: BaseRunManager.restart called without measurementType");
            return;
        }
        // Select input device (based on selection from menu)
        NSString *selectedDevice = self.selectionView.deviceName;
        if (selectedDevice == nil) return;
        BOOL ok = [self.capturer switchToDeviceWithName: selectedDevice];
#ifdef WITH_APPKIT
        if (!ok) {
            [self showErrorSheet: [NSString stringWithFormat:@"Cannot switch to input device %@", selectedDevice]];
            return;
        }
		if (self.measurementType.requires == nil) {
			[self.selectionView.bBase setEnabled: NO];
		} else {
            NSArray *calibrationNames = self.measurementType.requires.measurementNames;
            ok = [self.selectionView setBases: calibrationNames];
            if (!ok) {
#ifdef WITH_APPKIT
                [self showErrorSheet: @"No suitable calibrations"];
#else
                showWarningAlert(@"No suitable calibrations");
#endif
                return;
            }
            baseName = self.selectionView.baseName;
		}
#endif
        // Select or check output device (based on base measurement setting)
        if (self.measurementType.requires != nil && !self.measurementType.outputOnlyCalibration) {
            MeasurementType *baseType = (MeasurementType *)self.measurementType.requires;
            MeasurementDataStore *baseStore = [baseType measurementNamed: baseName];
            if (baseStore == nil) {
#ifdef WITH_APPKIT
                [self showErrorSheet: [NSString stringWithFormat:@"No base measurement named %@", baseName]];
#else
                showWarningAlert([NSString stringWithFormat:@"No base measurement named %@", baseName]);
#endif
                return;
            }
            NSString *deviceName = baseStore.output.device;
            ok = [self.outputView switchToDeviceWithName: deviceName];
            if (!ok) {
#ifdef WITH_APPKIT
                [self showErrorSheet: [NSString stringWithFormat:@"Cannot switch to output device %@", deviceName]];
#else
                showWarningAlert([NSString stringWithFormat:@"Cannot switch to output device %@", deviceName]);
#endif
                return;
            }
        }
        // Finally tell the input and output device handlers to get ready (if needed)
        ok = ([self prepareInputDevice] && [self prepareOutputDevice]);
        if (!ok) return;
        // All is well.
        VL_LOG_EVENT(@"restart", 0LL, self.measurementType.name);
#ifdef WITH_APPKIT
        [self.statusView.bPrepare setEnabled: YES];
#endif
	}
}

- (void)stop
{
    self.running = NO;
    self.preparing = NO;
    if (self.networkIODevice) {
        [self.networkIODevice reportStatus: @"Measurements complete"];
        MeasurementDataStore *ds = self.collector.dataStore;
        [ds trim];
        [self.networkIODevice reportResult: ds];
        // And show blue screen
        [self triggerNewOutputValue];
    }
    if (self.capturer) [self.capturer stop];
    self.capturer = nil;
    self.clock = nil;
}

- (IBAction)stopMeasuring: (id)sender
{
	VL_LOG_EVENT(@"stop", 0LL, @"");
	assert(self.running);
	self.running = NO;
    [self stop];
    [self.collector stopCollecting];
    [self.collector trim];
    self.statusView.detectCount = [NSString stringWithFormat: @"%d (after trimming 5%%)", self.collector.count];
    self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
    [self.statusView update: self];
	if (self.completionHandler) {
        [self.completionHandler performSelectorOnMainThread:@selector(openUntitledDocumentWithMeasurement:) withObject: self.collector.dataStore waitUntilDone: NO];
	} else {
#ifdef WITH_APPKIT
		AppDelegate *d = (AppDelegate *)[[NSApplication sharedApplication] delegate];
        [d performSelectorOnMainThread:@selector(openUntitledDocumentWithMeasurement:) withObject:self.collector.dataStore waitUntilDone:NO];
		[self.statusView.window close];
#else
		assert(0);
#endif
	}
}


- (void)triggerNewOutputValue
{
    if (!self.outputView) {
        // We have stopped measuring in the mean time
        return;
    }
    assert(self.outputView);
    if (VL_DEBUG) NSLog(@"triggerNewOutputValue called");
    [self.outputView performSelectorOnMainThread:@selector(showNewData) withObject:nil waitUntilDone:NO ];
}
- (void)triggerNewOutputValueAfterDelay
{
    // Randomize a 0..100ms delay before producing the next code.
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 1000000LL * (1+(rand()%100)));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        [self triggerNewOutputValue];
    });
}

- (void) prepareReceivedNoValidCode
{
    if (VL_DEBUG) NSLog(@"Prepare no reception\n");
    assert(self.preparing);
    // Check that we have waited long enough
    if ([self.clock now] < outputCodeTimestamp + prepareMaxWaitTime) return;
    // No data found within alotted time. Double the time, reset the count, change mirroring
    if (VL_DEBUG) NSLog(@"tsOutLatest=%llu, prepareDelay=%llu\n", outputCodeTimestamp, prepareMaxWaitTime);
    NSLog(@"prepare: detection %d failed for maxDelay=%lld. Doubling.", self.initialPrepareCount-prepareMoreNeeded, prepareMaxWaitTime);
    prepareMaxWaitTime *= 2;
    prepareMoreNeeded = self.initialPrepareCount;
    self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prepareMoreNeeded];
    self.statusView.detectAverage = @"";
    [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
    [self triggerNewOutputValue];
}

- (void) prepareReceivedValidCode: (NSString *)code
{
    if (VL_DEBUG) NSLog(@"prepare reception %@\n", code);
    assert(self.preparing);
    prepareMoreNeeded -= 1;
    self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prepareMoreNeeded];
    self.statusView.detectAverage = @"";
    [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
    if (VL_DEBUG) NSLog(@"prepareMoreMeeded=%d\n", prepareMoreNeeded);
    if (prepareMoreNeeded == 0) {
#ifdef WITH_SET_MIN_CAPTURE_DURATION
        NSLog(@"average detection algorithm duration=%lld µS", averageFinderDuration);
        [self.capturer setMinCaptureInterval: averageFinderDuration*2];
#endif
        self.statusView.detectCount = @"";
        self.statusView.detectAverage = @"";
        [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
        [self performSelectorOnMainThread: @selector(stopPreMeasuring:) withObject: self waitUntilDone: NO];
    }
    [self triggerNewOutputValue];
}

- (CIImage *)getNewOutputImage
{
    [NSException raise:@"BaseRunManager" format:@"Must override getNewOutputImage in subclass %@", [self class]];
    return nil;
}

- (NSString *)getNewOutputCode
{
    [NSException raise:@"BaseRunManager" format:@"Must override getNewOutputCode in subclass %@", [self class]];
    return nil;
}

- (void)newOutputDoneAt: (uint64_t)timestamp
{
    assert(self.collector);
    @synchronized(self) {
        if (outputCodeTimestamp != 0) {
            // We have already received the redraw for our mosyt recent generated code.
            // Again, redraw for some other reason, ignore.
            return;
        }
        assert(outputCodeTimestamp == 0);
        outputCodeTimestamp = timestamp;
        uint64_t tsOutToRemember = outputCodeTimestamp;
        if (self.running) {
            [self.collector recordTransmission: self.outputCode at: tsOutToRemember];
            VL_LOG_EVENT(@"transmission", tsOutToRemember, self.outputCode);
        }
    }
}

- (void)newOutputDone
{
    assert(self.collector);
    [self newOutputDoneAt: [self.clock now]];
}

- (void)setFinderRect: (NSorUIRect)theRect
{
	[NSException raise:@"BaseRunManager" format:@"Must override setFinderRect in subclass %@", [self class]];
}


- (void)newInputDone:(NSString *)inputCode count:(int)count at:(uint64_t)inputTimestamp
{
    if (self.outputCode == nil) {
        if (VL_DEBUG) NSLog(@"newInputDone called, but no output code yet\n");
        return;
    }
    if ([inputCode isEqualToString:@"undetectable"]) {
        // black/white detector needs to be kicked (black and white levels have come too close)
        NSLog(@"Detector range too small, generating new code");
        [self triggerNewOutputValue];
        if (self.networkIODevice) [self.networkIODevice reportHeartbeat];
        return;
    }
    if ([inputCode isEqualToString:@"uncertain"]) {
        // Unsure what we have detected, probably nothing. Leave it be for a while then change.
        prevInputCodeDetectionCount++;
        if (prevInputCodeDetectionCount % 250 == 0) {
            NSLog(@"Received uncertain code for too long. Generating new one.");
            [self triggerNewOutputValue];
        }
        if (self.networkIODevice) [self.networkIODevice reportHeartbeat];
        return;
    }
    //
    // Check to see whether the code appears to be a URL. If this is the case, and we are
    // in a networked session,
    if ([inputCode hasPrefix:@"http"] && ![inputCode isEqualToString: prevInputCode]) {
        prevInputCode = inputCode;
        if (!self.networkIODevice) {
            showWarningAlert([NSString stringWithFormat:@"Not in network session. Received unexpected URL code: %@", inputCode]);
            return;
        }
        if (networkServer) {
            NSLog(@"BaseRunManager (with network server): prepare code reported back");
            return;
        } else {
            [self.networkIODevice openClient: inputCode];
        }
    }

    //
    // If we are in a netwrk session we report the code back to the other side.
    //
    if (self.networkIODevice) {
        [self.networkIODevice reportReception:inputCode count:prevInputCodeDetectionCount at:inputTimestamp];
    }
    // Is this code the same as the previous one detected?
    if (prevInputCode && [inputCode isEqualToString: prevInputCode]) {
        prevInputCodeDetectionCount++;
        if (networkHelper) {
            // xxxjack is this correct for display helpers too????
            return;
        }
        if (prevInputCodeDetectionCount == 3) {
            // Aftter we've detected 3 frames with the right light level
            // we generate a new one.
            [self triggerNewOutputValueAfterDelay];
        }
        // And if we keep on detecting the same code after that we eventually give up.
        if ((self.running || self.preparing) && (prevInputCodeDetectionCount % 250) == 0) {
            showWarningAlert(@"Old code detected too often. Generating new one.");
            [self triggerNewOutputValue];
        }
        return;
    }
    // Is this the code we wanted?
    if ([inputCode isEqualToString: self.outputCode]) {
        if (self.running) {
            if (inputTimestamp == 0) {
                showWarningAlert(@"newInputDone called before newInputStart was called");
            }
            BOOL ok = [self.collector recordReception:inputCode at:inputTimestamp];
            if (!ok) {
                NSLog(@"Received code %@ before it was transmitted", self.outputCode);
                return;
            }
            VL_LOG_EVENT(@"reception", inputTimestamp, inputCode);
            self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
            self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
            [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
            prevInputCode = self.outputCode;
            prevInputCodeDetectionCount = 0;
            if (VL_DEBUG) NSLog(@"Received: %@", self.outputCode);
            // Generate new output code later, after we've detected this one a few times.
        } else if (self.preparing) {
            [self prepareReceivedValidCode: inputCode];
        }
        return;
    }
    // We did not detect the code we expected
    if (self.preparing) {
        [self prepareReceivedNoValidCode];
        return;
    }
    // While idle, change output value once in a while
    if (!self.running && !self.preparing) {
        [self triggerNewOutputValue];
    }
}

- (void) newInputDone: (CVImageBufferRef) image at: (uint64_t) timestamp
{
    [NSException raise:@"BaseRunManager" format:@"Must override newInputDone:at: in subclass %@", [self class]];
}

- (void)newInputDone: (void*)buffer
                size: (int)size
            channels: (int)channels
                  at: (uint64_t)timestamp
				  duration: (uint64_t)duration
{
	[NSException raise:@"BaseRunManager" format:@"Must override newInputDone:buffer:size:channels:at in subclass %@", [self class]];
}

@end
