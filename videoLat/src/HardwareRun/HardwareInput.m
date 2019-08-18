#import "HardwareInput.h"
#import "EventLogger.h"
#import "PythonLoader.h"

// How long we keep a random light level before changing it, when not running or
// prerunning. In microseconds.
#define IDLE_LIGHT_INTERVAL 200000

@implementation HardwareInput
@synthesize deviceID;
@synthesize deviceName;

- (HardwareInput *)init
{
    self = [super init];
    if (self) {
		self.samplePeriodMs = 10;
    }
    return self;
}

- (void)dealloc
{
	[self stop];
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

- (void) awakeFromNib
{    
    [super awakeFromNib];
    if (self.outputManager == nil) self.outputManager = self.manager;
    if (self.clock == nil) self.clock = self;
    assert(self.bDriverStatus);
	self.samplePeriodMs = 10;
	[self _updatePeriod];
    [self restart];

    // Setup for callbacks

	if (VL_DEBUG) NSLog(@"Devices: %@\n", [self deviceNames]);
}

- (uint64_t)now
{
    UInt64 timestamp;
	timestamp = monotonicMicroSecondClock();
    return timestamp;
}

- (bool)available
{
	return self.device && self.device.available;
}

- (NSString*) deviceName
{
	return self.device.deviceName;
}

- (NSString*) deviceID
{
	return self.device.deviceID;
}

- (NSArray *)deviceNames
{
    assert(0);
    return @[];
}

- (BOOL)switchToDeviceWithName: (NSString *)selectedDevice
{
    NSString *oldDevice = nil;
    if (self.device)
        oldDevice = [self.device deviceName];
    if (selectedDevice && oldDevice && [selectedDevice isEqualToString: oldDevice])
        return YES;

    self.device = nil;

    if (selectedDevice == nil)
        return NO;
    // Note we call _switchToDevice asynchronously so the UI update indicating that we're
    // loading is visible.
    self.bDriverStatus.stringValue = @"Loading...";
    [self.bDriverStatus display];
    [self performSelectorOnMainThread:@selector(_switchToDevice:) withObject:selectedDevice waitUntilDone:NO];
    return YES;
}


- (void)_switchToDevice: (NSString *)selectedDevice
{
    self.bDriverStatus.stringValue = @"Loading...";
    [self.bDriverStatus display];
    PythonLoader *pl = [PythonLoader sharedPythonLoader];
    uint64_t loadStartTime = [self.clock now];
    BOOL ok = [pl loadPackageNamed: selectedDevice];
    uint64_t loadDoneTime = [self.clock now];
    NSLog(@"Loading %@ Python code took %f seconds", selectedDevice, ((float)(loadDoneTime-loadStartTime)/1000000.0));
    if (!ok) {
        self.bDriverStatus.stringValue = @"Not loaded";
        [self.bDriverStatus display];
        [self.manager showErrorSheet: [NSString stringWithFormat:@"HardwareRunManager: Programmer error: Python module %@ cannot be imported", selectedDevice]];
        return;
    }
    self.bDriverStatus.stringValue = @"Loaded";
    [self.bDriverStatus display];
    Class deviceClass = NSClassFromString(selectedDevice);
    if (deviceClass == nil) {
        [self.manager showErrorSheet: [NSString stringWithFormat:@"HardwareRunManager: Programmer error: class %@ does not exist", selectedDevice]];
        return;
    }
    @try {
        self.device = [[deviceClass alloc] init];
        connected = [self.device available];
    } @catch (NSException *exception) {
        [self.manager showErrorSheet: [NSString stringWithFormat:@"Caught exception %@ while allocating hardware device class: %@", [exception name], [exception reason]]];
    }
    if (self.device == nil) {
        [self.manager showErrorSheet: [NSString stringWithFormat:@"HardwareRunManager: cannot allocate %@ object", deviceClass]];
    }

    self.bDriverStatus.stringValue = (connected ? @"Connected" : @"Disconnected");
    minInputLevel = 1.0;
    maxInputLevel = 0.0;
    inputLevel = -1;
    [self restart];
    // Because this runs asynchronously we should infor the runmanager again,
    // so it can enable prepare button and all that
    if (connected)
        [self.manager inputSelectionChanged: self];
}

- (void)pauseCapturing: (BOOL) pause
{
	capturing = NO;
}

- (void) startCapturing: (BOOL) showPreview
{
	[self restart];
	capturing = YES;
}

- (void) stopCapturing
{
	capturing = NO;
	[self stop];
}

- (void)setMinCaptureInterval:(uint64_t)interval
{
}


- (void)restart
{
    @synchronized(self) {
		if (!alive) {
            alive = YES;
            [self performSelectorInBackground:@selector(_periodic:) withObject:self];
        }
    }
}

- (void)stop
{
	alive = NO;
}

- (void)setOutputCode: (NSString *)newValue report: (BOOL)report
{
	assert(alive);
	outputCode = newValue;
	newOutputValueWanted = YES;
    reportNewOutput = report;
}

- (void)_periodic: (id)sender
{
    BOOL first = YES;
    BOOL outputLevelChanged = NO;
	uint64_t lastUpdateCall = 0;
    @try {
        while(alive) {
            BOOL nConnected = self.device && [self.device available];
            //
            // Compute new light level, if needed
            //
            @synchronized(self) {
                if (newOutputValueWanted) {
                    if ([outputCode isEqualToString: @"white"]) {
                        outputLevel = 1;
                        outputLevelChanged = YES;
                    } else if ([outputCode isEqualToString: @"black"]) {
                        outputLevel = 0;
                        outputLevelChanged = YES;
                    } else {
                        outputLevel = (double)rand() / (double)RAND_MAX;
                    }
                    newOutputValueWanted = NO;
                    if (reportNewOutput) {
                        reportNewOutput = NO;
                        [self.outputManager newOutputDone];
                    }
                    if (VL_DEBUG) NSLog(@"HardwareRunManager: outputLevel %f at %lld", outputLevel, outputTimestamp);
                }
            }
            NSString *outputLevelStr = [NSString stringWithFormat:@"%f", outputLevel];
            //
            // Set new output light level, get new input light level
            //
            double nInputLevel = [self.device light: outputLevel];
            uint64_t loopTimestamp = [self.clock now];
            if (outputLevelChanged) {
                outputTimestamp = loopTimestamp;
                VL_LOG_EVENT(@"hardwareOutput", loopTimestamp, outputLevelStr);
            }
            //
            // Process input level change
            //
            NSString *inputLevelStr = [NSString stringWithFormat:@"%f", inputLevel];
            if (nInputLevel != inputLevel) {
                VL_LOG_EVENT(@"hardwareInput", loopTimestamp, inputLevelStr);
            }
            if (nInputLevel < 0) {
				// Negative values are errors, such as disconnected, etc.
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
                        || capturing
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
                if (!capturing && [self.clock now] > outputTimestamp + IDLE_LIGHT_INTERVAL)
                    newOutputValueWanted = YES;
            }
            outputLevelChanged = NO;
            double interval = (0.001 * (double)self.samplePeriodMs);
            [NSThread sleepForTimeInterval:interval];
        }
    } @catch (NSException *exception) {
		[self.manager showErrorSheet: [NSString stringWithFormat:@"Caught exception %@ in hardware handler: %@", [exception name], [exception reason]]];
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

        self.bDriverStatus.stringValue = (connected ? @"Connected" : @"Disconnected");
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
		// Check for detections and report them if wanted
		if (VL_DEBUG) NSLog(@" input %@ (%f  range %f..%f) output %@", inputCode, inputLevel, minInputLevel, maxInputLevel, outputCode);
		if (capturing) {
			if (prevInputCode && [inputCode isEqualToString: prevInputCode]) {
				prevInputCodeDetectionCount++;
			}
			prevInputCode = inputCode;
			[self.manager newInputDone:inputCode count:prevInputCodeDetectionCount at:inputTimestamp];
		}
		// Finally check for error messages and report them
        NSString *msg = self.device.lastErrorMessage;
        if (msg && ![msg isEqualToString:lastError]) {
            [self.manager showErrorSheet: [NSString stringWithFormat: @"Hardware device error: %@", msg]];
            [self stop];
        }
    }
}

@end
