//
//  NetworkRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "NetworkRunManager.h"
#import "AppDelegate.h"
#import "MachineDescription.h"
#import "NetworkInput.h"
#import "EventLogger.h"

///
/// How many times do we want to get a message that the prerun code has been detected?
/// This define is used on the master side, and stops the prerun sequence. It should be high enough that we
/// have a reasonable measurement of the RTT and the clock difference.
#define PREPARE_COUNT 32


///
/// What is the maximum time we try to detect a QR-code (in microseconds)?
/// This define is used on the master side, to trigger a new QR code if the old one was never detected, for some reason.
#define MAX_DETECTION_INTERVAL 5000000LL

@implementation NetworkRunManager
@synthesize selectionView;
@synthesize outputView;
@dynamic clock;

+ (void)initialize
{
    // Unsure whether we need to register our class?

    // We also register ourselves for send-only, as a slave. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"QR Code Transmission"];
    [BaseRunManager registerNib: @"MasterSenderRun" forMeasurementType: @"QR Code Transmission"];
    // We register ourselves for receive-only, as a slave. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"QR Code Reception"];
    [BaseRunManager registerNib: @"SlaveReceiverRun" forMeasurementType: @"QR Code Reception"];

    [BaseRunManager registerClass: [self class] forMeasurementType: @"Reception Calibrate using Other Device"];
    [BaseRunManager registerNib: @"SlaveReceiverCameraCalibrationRun" forMeasurementType: @"Reception Calibrate using Other Device"];
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Transmission Calibrate using Other Device"];
    [BaseRunManager registerNib: @"MasterSenderScreenCalibrationRun" forMeasurementType: @"Transmission Calibrate using Other Device"];

#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"QR Code Reception"];
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"Reception Calibrate using Other Device"];
    [BaseRunManager registerSelectionNib: @"NetworkInputSelectionView" forMeasurementType: @"QR Code Transmission"];
    [BaseRunManager registerSelectionNib: @"NetworkInputSelectionView" forMeasurementType: @"Transmission Calibrate using Other Device"];
#endif
}

- (NetworkRunManager *) init
{
    self = [super init];
    if (self) {
        handlesInput = NO;
        handlesOutput = NO;
        slaveHandler = NO;
    }
    return self;
}

- (void) dealloc
{
    
}

- (void) awakeFromNib
{
    if (self.capturer && ![self.capturer isKindOfClass: [NetworkInput class]]) {
        slaveHandler = YES;
    }
    [super awakeFromNib];
    assert(self.clock);
    assert(self.networkDevice);
    if (handlesInput) {
#if 0
        // This isn't set for screen calibrate using remote camera...
        assert(self.finder);
#endif
    } else {
        assert(self.inputCompanion);
        assert(self.capturer == nil);
        assert(self.clock);
        assert(self.clock == self.inputCompanion.clock);
    }
    // If we don't handle output (i.e. output is going through video) we start the server and
    // report the port number
    if (!handlesOutput) {
        [self.networkDevice tmpOpenServer];
    }
}

- (BOOL)prepareInputDevice
{
    if (handlesInput && ![self.capturer isKindOfClass: [NetworkInput class]]) {
        DeviceDescription *deviceDescriptorToSend = nil;
        if (self.measurementType.isCalibration) {
            if (self.selectionView) assert(self.selectionView.bBase == nil);
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
        [self.networkDevice tmpSetDeviceDescriptor: deviceDescriptorToSend];
		[self.capturer startCapturing:YES];
	}
	return YES;
}

- (void)stop
{
	self.running = NO;
	self.preparing = NO;
	[self.networkDevice tmpUpdateStatus: @"Measurements complete"];
    MeasurementDataStore *ds = self.collector.dataStore;
	[ds trim];
    [self.networkDevice tmpSendResult: ds];
}

- (void)newOutputDone
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newOutputDone in subclass"];
    assert(handlesOutput);
}

- (void)setFinderRect: (NSorUIRect)theRect
{
	[NSException raise:@"NetworkRunManager" format:@"Must override setFinderRect in subclass"];
}

- (void)newInputDoneNoData
{
    if (!self.running)
        return;
    
    uint64_t now = [self.clock now];
    if (now - lastDetectionReceivedTime < MAX_DETECTION_INTERVAL)
        return;

    // Nothing detected for a long time. Record this fact, and generate a new code.

    BOOL ok = [self.collector recordReception: @"nothing" at: now];
	VL_LOG_EVENT(@"noReception", now, @"nothing");
    assert(!ok);
    [self.outputCompanion triggerNewOutputValue];
    // This isn't true, but works well:
    lastDetectionReceivedTime = now;
}

///
/// This version of newInputDone is used when running in master mode, it signals a reception
/// by the network module
///
- (void) newInputDone: (NSString *)code count: (int)count at: (uint64_t) timestamp
{
    lastDetectionReceivedTime = timestamp;
    if (self.preparing) {
        NSString *prepareCode = [self.capturer genPrepareCode];
        if (prepareCode == nil || ![prepareCode isEqualToString:code]) {
            NSLog(@"Peer sent us code %@ but we expected %@", code, prepareCode);
            return;
        }
        if (count < PREPARE_COUNT) {
            self.statusView.detectCount = [NSString stringWithFormat: @"%d", count];
        } else {
            self.statusView.detectCount = @"";
            [self performSelectorOnMainThread:@selector(stopPreMeasuring:) withObject:self waitUntilDone:YES];
        }
        [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
    }
	// Unless we are prerunning we expect a timestamp
	if (timestamp == 0) {
		NSLog(@"Received code %@ without timestamp, ignoring", code);
		return;
	}
    if (self.running) {
        if (VL_DEBUG) NSLog(@"Running, received code %@", code);
        if (self.outputCompanion.outputCode == nil) {
            NSLog(@"newInputDone called with code %@, but no output code yet\n", code);
            return;
        }
    
        // Compare the code to what was expected.
        if (count > 1 && [code isEqualToString:prevInputCode]) {
            if (VL_DEBUG) NSLog(@"Received old output code again: %@, %d times", code, count);
            if ((count % 128) == 0) {
                showWarningAlert([NSString stringWithFormat:@"QR code not detected in time: %@", self.outputCompanion.outputCode]);

                [self.outputCompanion triggerNewOutputValue];
            }
        } else if ([code isEqualToString: self.outputCompanion.outputCode]) {
            // Correct code found.
            // Let's first report it.
            BOOL ok = [self.collector recordReception: code at: timestamp];
			VL_LOG_EVENT(@"reception", timestamp, code);
			if (VL_DEBUG) NSLog(@"Reported %@ at %lld, ok=%d", code, timestamp, ok);
            if (!ok) {
				showWarningAlert(@"Received QR-code that has not been transmitted yet");
            }

            // Now do a sanity check that it is greater than the previous detected code
            if (prevInputCode && [prevInputCode length] >= [self.outputCompanion.outputCode length] && [prevInputCode compare:self.outputCompanion.outputCode] >= 0) {
				showWarningAlert(@"Received QR-code that is not monotonically increasing");
            }
            // Now let's remember it so we don't generate "bad code" messages
            // if we detect it a second time.
            prevInputCode = self.outputCompanion.outputCode;
            prevInputCodeDetectionCount = 0;
            if (VL_DEBUG) NSLog(@"Received: %@", self.outputCompanion.outputCode);
            // Now generate a new output code.
            [self.outputCompanion triggerNewOutputValueAfterDelay];
		} else if (self.outputCompanion.prevOutputCode && [code isEqualToString:self.outputCompanion.prevOutputCode]) {
			NSLog(@"Received old code %@", code);
        } else {
            // We have transmitted a code, but received a different one??
            NSLog(@"Bad data: expected %@, got %@", self.outputCompanion.outputCode, code);
            showWarningAlert([NSString stringWithFormat:@"Unexpected QR code received: %@", code]);

            [self.outputCompanion triggerNewOutputValue];
        }
        self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
        self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
        [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
    }
}

- (void)reportRemoteResults: (MeasurementDataStore *)mr
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

///
/// This version of newInputDone is used when running in slave mode, it signals that the camera
/// has captured an input.
///
- (void) newInputDone: (CVImageBufferRef)image at:(uint64_t)timestamp
{
    @synchronized(self) {
        assert(handlesInput);
		assert(self.finder);
        uint64_t finderStartTime = [self.clock now];
        NSString *code = [self.finder find: image];
        uint64_t finderStopTime = [self.clock now];
        uint64_t finderDuration = finderStopTime - finderStartTime;
        BOOL foundQRcode = (code != NULL);
        if (foundQRcode) {
			// Compute average duration of our code detection algorithm
			if (averageFinderDuration == 0)
				averageFinderDuration = finderDuration;
			else
				averageFinderDuration = (averageFinderDuration+finderDuration)/2;

            if (prevInputCode && [code isEqualToString: prevInputCode]) {
                // We have seen this code before. Only increment the detection count.
                prevInputCodeDetectionCount++;
				if (VL_DEBUG) NSLog(@"Found %d copies since %lld of %@", prevInputCodeDetectionCount, tsLastReported, prevInputCode);
            } else {
                // We found a new QR code (at least, different from the last detection).
                // Remember when we first detected it, and then see what we should do with it.
                prevInputCode = code;
                prevInputCodeDetectionCount = 1;
                tsLastReported = timestamp;
                if (VL_DEBUG) NSLog(@"Found QR-code: %@", code);
                
                // If it is a URL it is probably a prerun QR-code (which is a URL, so that if
                // the receiver isn't running videoLat but an ordinary QR-code app they will be sent
                // to the website where they can download videoLat).
                // The prerun QR-code contains contact information for the server running on the
                // master copy of videoLat.
				if ([code hasPrefix:@"http"]) {
                    [self.networkDevice tmpOpenClient: code];

				}
				else {
#ifdef WITH_SET_MIN_CAPTURE_DURATION
					if (averageFinderDuration && !captureDurationWasSet) {
						captureDurationWasSet = YES;
						[self.capturer setMinCaptureInterval:averageFinderDuration];
					}
#endif
				}
                
            }
            // All QR codes are sent back to the master, assuming we have a connection to the master already.
            [self.networkDevice tmpReport:code count:prevInputCodeDetectionCount at:tsLastReported];
        } else {
             // No QR-code detected. Send a heartbeat every second.
            [self.networkDevice tmpHeartbeat];
        }
    }
}

- (void)newInputDone: (void*)buffer
                size: (int)size
            channels: (int)channels
                  at: (uint64_t)timestamp
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newInputDone in subclass"];
}


- (IBAction)startPreMeasuring: (id)sender
{
    @synchronized(self) {
		[self.networkDevice tmpUpdateStatus: @"Determining RTT"];
        assert(handlesInput);
        assert(self.statusView);
#ifdef WITH_APPKIT
        [self.statusView.bPrepare setEnabled: NO];
#endif
        [self.statusView.bRun setEnabled: NO];
        [self.statusView.bStop setEnabled: NO];

        // Do actual prerunning
        if (!handlesOutput) {
            BOOL ok = [self.outputCompanion companionStartPreMeasuring];
            if (!ok) return;
        }
        self.preparing = YES;
        [self.outputCompanion triggerNewOutputValue];
    }
}

- (IBAction)stopPreMeasuring: (id)sender
{
    @synchronized(self) {
        assert(handlesInput);
        self.preparing = NO;
        if (!handlesOutput)
            [self.outputCompanion companionStopPreMeasuring];
//        outputLevel = 0.5;
//        newOutputValueWanted = NO;
        assert(self.statusView);
#ifdef WITH_APPKIT
        [self.statusView.bPrepare setEnabled: NO];
#endif
        [self.statusView.bRun setEnabled: NO];
        //
        // We should now have the correct output device (locally) and input device (received from remote)
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
                if (handlesOutput) {
                    assert(self.outputView);
                }
                // For runs where we are responsible for output the output device should match
                if (![baseStore.output.deviceID isEqualToString:self.outputCompanion.outputView.deviceID]) {
                    errorMessage = [NSString stringWithFormat:@"Base measurement uses output %@, current measurement uses %@", baseStore.output.device, self.outputView.deviceName];
                }
            }
        }
        DeviceDescription *remoteDeviceDescription = [self.networkDevice remoteDeviceDescription];
        if (errorMessage == nil && remoteDeviceDescription == nil) {
            errorMessage = @"No device description received from remote (slave) partner.";
        }
        if (errorMessage) {
			[self.networkDevice tmpUpdateStatus: @"Missing calibration"];
			showWarningAlert(errorMessage);
	   }
        // Remember the input and output device in the collector
        if (baseStore) {
            [self.collector.dataStore useOutputCalibration:baseStore];
        } else {
            self.collector.dataStore.output = [[DeviceDescription alloc] initFromOutputDevice: self.outputCompanion.outputView];
        }
        self.collector.dataStore.input = remoteDeviceDescription;

		[self.networkDevice tmpUpdateStatus: @"Ready to run"];

        if (!self.statusView) {
            // XXXJACK Make sure statusview is active/visible
        }
        assert(self.statusView);
        [self.statusView.bRun setEnabled: YES];
        [self.statusView.bStop setEnabled: NO];
        [self.outputCompanion triggerNewOutputValue];
    }
}

- (IBAction)startMeasuring: (id)sender
{
    @synchronized(self) {
		[self.networkDevice tmpUpdateStatus: @"Running measurements"];
        if (!self.statusView) {
            // XXXJACK Make sure statusview is active/visible
        }
        assert(self.statusView);
#ifdef WITH_APPKIT
        [self.statusView.bPrepare setEnabled: NO];
#endif
        [self.statusView.bRun setEnabled: NO];
        [self.statusView.bStop setEnabled: YES];
        self.running = YES;
        if (!handlesOutput)
            [self.outputCompanion companionStartMeasuring];
        [self.collector startCollecting: self.measurementType.name];
        [self.outputCompanion triggerNewOutputValue];
    }
}

@end
