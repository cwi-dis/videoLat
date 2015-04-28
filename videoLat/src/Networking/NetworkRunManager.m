//
//  NetworkRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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
#define PRERUN_COUNT 32

///
/// How often do we send a message if we have not received a QR-code (in microseconds)?
/// This define is used on the slave side, it keeps the connection open and the RTT clock difference.
/// In addition, it will trigger the master side to emit a fresh QR code if the current QR code hasn't been
/// detected for some time.
#define HEARTBEAT_INTERVAL 1000000LL

///
/// What is the maximum time we try to detect a QR-code (in microseconds)?
/// This define is used on the master side, to trigger a new QR code if the old one was never detected, for some reason.
#define MAX_DETECTION_INTERVAL 5000000LL


///
/// Helper function: get an uint64_t from a dictionary item, if it exists
static uint64_t getTimestamp(NSDictionary *data, NSString *key)
{
    id timeObject = [data objectForKey: key];
    if (timeObject == nil) {
        NSLog(@"No key %@ in %@", key, data);
        return 0;
    }
    if ([timeObject respondsToSelector:@selector(unsignedLongLongValue)]) {
        return [timeObject unsignedLongLongValue];
    }
    uint64_t timestamp;
    if (sscanf([timeObject UTF8String], "%lld", &timestamp) == 1) {
        return timestamp;
    }
    NSLog(@"Cannot convert to uint64: %@", timeObject);
    return 0;
}

@interface SimpleRemoteClock : NSObject  <RemoteClockProtocol> {
	int64_t localTimeToRemoteTime;
    uint64_t rtt;
    bool initialized;
};
- (uint64_t)remoteNow: (uint64_t) now;
- (void)remote: (uint64_t)remote between: (uint64_t)start and: (uint64_t) finish;
- (uint64_t)rtt;
@end

@implementation SimpleRemoteClock
- (SimpleRemoteClock *) init
{
	self = [super init];
	localTimeToRemoteTime = 0;
    initialized = false;
	return self;
}

- (uint64_t)remoteNow: (uint64_t) now
{
    if (!initialized) return 0;
	return now + localTimeToRemoteTime;
}

- (void)remote: (uint64_t)remote between: (uint64_t)start and: (uint64_t) finish
{
    if (finish < start) {
        NSLog(@"SimpleRemoteClock: local timeinterval start %lld > end %lld, assuming local NTP re-sync", start, finish);
        VL_LOG_EVENT(@"negativeRTT", start-finish, @"");
        return;
    }
    rtt = finish-start;
    VL_LOG_EVENT(@"RTT", rtt, @"");
	uint64_t mid = (finish+start)/2;
	localTimeToRemoteTime = (int64_t)remote - (int64_t)mid;
    VL_LOG_EVENT(@"NewMasterTime", [self remoteNow: finish], @"");
    initialized = true;
}

- (uint64_t) rtt
{
    return rtt;
}

@end

@implementation NetworkRunManager
@synthesize selectionView;
@synthesize outputView;

+ (void)initialize
{
    // Unsure whether we need to register our class?

    // We also register ourselves for send-only, as a slave. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Transmission (Master,Server)"];
    [BaseRunManager registerNib: @"MasterSenderRun" forMeasurementType: @"Video Transmission (Master,Server)"];
    // We register ourselves for receive-only, as a slave. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Reception (Slave,Client)"];
    [BaseRunManager registerNib: @"SlaveReceiverRun" forMeasurementType: @"Video Reception (Slave,Client)"];

    [BaseRunManager registerClass: [self class] forMeasurementType: @"Camera Calibrate using Remote Calibrated Screen (Slave,Client)"];
    [BaseRunManager registerNib: @"SlaveReceiverCameraCalibrationRun" forMeasurementType: @"Camera Calibrate using Remote Calibrated Screen (Slave,Client)"];
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Screen Calibrate using Remote Calibrated Camera (Master,Server)"];
    [BaseRunManager registerNib: @"MasterSenderScreenCalibrationRun" forMeasurementType: @"Screen Calibrate using Remote Calibrated Camera (Master,Server)"];

#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"Video Reception (Slave,Client)"];
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"Camera Calibrate using Remote Calibrated Screen (Slave,Client)"];
    [BaseRunManager registerSelectionNib: @"NetworkInputSelectionView" forMeasurementType: @"Video Transmission (Master,Server)"];
    [BaseRunManager registerSelectionNib: @"NetworkInputSelectionView" forMeasurementType: @"Screen Calibrate using Remote Calibrated Camera (Master,Server)"];
#endif
}

- (NetworkRunManager *) init
{
    self = [super init];
    if (self) {
        handlesInput = NO;
        handlesOutput = NO;
        slaveHandler = NO;
		remoteDevice = nil;
		statusToPeer = nil;
		didReceiveData = NO;
    }
    return self;
}

- (void) dealloc
{
    
}

- (void) awakeFromNib
{
	if (self.selectionViewForStatusOnly == nil)
		self.selectionViewForStatusOnly = self.selectionView;
    if (self.capturer && ![self.capturer isKindOfClass: [NetworkInput class]]) {
        slaveHandler = YES;
    }
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
    assert(self.clock);
    // If we don't handle output (i.e. output is going through video) we start the server and
    // report the port number
    if (!handlesOutput) {
        assert(self.protocol == nil);
        self.protocol = [[NetworkProtocolServer alloc] init];
        self.protocol.delegate = self;
#ifdef WITH_UIKIT
        self.selectionViewForStatusOnly.bOurPort.text = [NSString stringWithFormat:@"%d", self.protocol.port];
#else
        self.selectionViewForStatusOnly.bOurPort.intValue = self.protocol.port;
#endif
    }
    // If we handle output (i.e. we get video from the camera and report QR codes to the server)
    // we only allocate a clock, the client-side of the network connection will be created once we
    // know ip/port (which will come in encoded as a QR-code)
    if (handlesOutput) {
        if (self.remoteClock == nil) {
            _keepRemoteClock = [[SimpleRemoteClock alloc] init];
            self.remoteClock = _keepRemoteClock;
        }
    }
}

- (void) _updateStatus: (NSString *)status
{
#ifdef WITH_UIKIT
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.outputView) {
			self.outputView.bPeerStatus.text = status;
		}
		if (self.selectionViewForStatusOnly) {
			self.selectionViewForStatusOnly.bOurStatus.text = status;
		}
	});

#else
	if (self.outputView) {
		self.outputView.bPeerStatus.stringValue = status;
	}
	if (self.selectionViewForStatusOnly) {
		self.selectionViewForStatusOnly.bOurStatus.stringValue = status;
	}
#endif
}

- (IBAction)selectionChanged:(id)sender
{
	assert(handlesInput);
}

- (IBAction)selectBase:(id)sender
{
	// This method is only called on the slave side. We need to obtain the
	// base measurement for our input device, and set up for it to be transmitted
	// to the master side.
	assert(handlesInput);
	[self restart];
}

- (BOOL)prepareInputDevice
{
    if (handlesInput && ![self.capturer isKindOfClass: [NetworkInput class]]) {
		deviceDescriptorToSend = nil;
        if (self.measurementType.isCalibration) {
            if (self.selectionView) assert(self.selectionView.bBase == nil);
			assert(self.capturer);
			deviceDescriptorToSend = [[DeviceDescription alloc] initFromInputDevice: self.capturer];
        } else {
            if (self.selectionView) baseName = [self.selectionView baseName];
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
		[self.capturer startCapturing:YES];
	}
	return YES;
}

- (void)stop
{
	self.running = NO;
	self.preRunning = NO;
	[self _updateStatus: @"Measurements complete"];
	statusToPeer = @"Measurements complete";
    MeasurementDataStore *ds = self.collector.dataStore;
	[ds trim];
    if (self.protocol && ds) {
        NSData *dsData = [NSKeyedArchiver archivedDataWithRootObject: ds];
        assert(dsData);
        NSString *dsString = [dsData base64EncodedStringWithOptions:0];
        assert(dsString);
        [self.protocol send: @{@"measurementResults" : dsString}];
    }
}

- (void)triggerNewOutputValue
{
	[NSException raise:@"NetworkRunManager" format:@"Must override triggerNewOutputValue in subclass"];
    assert(handlesOutput);
}

- (CIImage *)newOutputStart
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newOutputStart in subclass"];
    assert(handlesOutput);
	return nil;
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


- (void)newInputStart
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newInputStart in subclass"];
}

- (void) newInputStart:(uint64_t)timestamp
{
    @synchronized(self) {
        assert(handlesInput);
		tsFrameEarliest = tsFrameLatest;
		tsFrameLatest = timestamp;

		// Sanity check: times should be monotonically increasing
		if (tsFrameEarliest >= tsFrameLatest) {
#ifdef WITH_APPKIT
			NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: input clock not monotonically increasing."
											 defaultButton:@"OK"
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat:@"Previous value was %lld, current value is %lld.\nConsult Helpfile if this error persists.",
							  (long long)tsFrameEarliest,
							  (long long)tsFrameLatest];
			[alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
#else
			showWarningAlert(@"Input clock has gone back in time");
#endif
		}
    }
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
    if (self.preRunning) {
        if (prerunCode == nil || ![prerunCode isEqualToString:code]) {
            NSLog(@"Peer sent us code %@ but we expected %@", code, prerunCode);
            return;
        }
        if (count < PRERUN_COUNT) {
            self.statusView.detectCount = [NSString stringWithFormat: @"%d", count];
        } else {
            self.statusView.detectCount = @"";
            [self stopPreMeasuring: self];
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
#ifdef WITH_APPKIT
                NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: current QR code not detected."
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"QR-code %@ generated but %@ detected, %d times. Generating new one.",
                                  self.outputCompanion.outputCode, code, count];
                [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
#endif
                [self.outputCompanion triggerNewOutputValue];
            }
        } else if ([code isEqualToString: self.outputCompanion.outputCode]) {
            // Correct code found.
            // Let's first report it.
            BOOL ok = [self.collector recordReception: code at: timestamp];
			VL_LOG_EVENT(@"reception", timestamp, code);
			if (VL_DEBUG) NSLog(@"Reported %@ at %lld, ok=%d", code, timestamp, ok);
            if (!ok) {
#ifdef WITH_UIKIT
				showWarningAlert(@"Received QR-code that has not been transmitted yet");
#else
                NSAlert *alert = [NSAlert alertWithMessageText:@"Reception before transmission."
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"Code %@ was transmitted at (unknown), but received at %lld.\nConsult Helpfile if this error persists.",
                                  self.outputCompanion.outputCode,
                                  (long long)timestamp];
                [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
#endif
            }

            // Now do a sanity check that it is greater than the previous detected code
            if (prevInputCode && [prevInputCode length] >= [self.outputCompanion.outputCode length] && [prevInputCode compare:self.outputCompanion.outputCode] >= 0) {
#ifdef WITH_UIKIT
				showWarningAlert(@"Received QR-code that is not monotonically increasing");
#else
                NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: input QR-code not monotonically increasing."
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"Previous value was %@, current value is %@.\nConsult Helpfile if this error persists.",
                                  prevInputCode, self.outputCompanion.outputCode];
                [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
#endif
            }
            // Now let's remember it so we don't generate "bad code" messages
            // if we detect it a second time.
            prevInputCode = self.outputCompanion.outputCode;
            prevInputCodeDetectionCount = 0;
            if (VL_DEBUG) NSLog(@"Received: %@", self.outputCompanion.outputCode);
            // Now generate a new output code.
            [self.outputCompanion triggerNewOutputValue];
		} else if (self.outputCompanion.prevOutputCode && [code isEqualToString:self.outputCompanion.prevOutputCode]) {
			NSLog(@"Received old code %@", code);
        } else {
            // We have transmitted a code, but received a different one??
            NSLog(@"Bad data: expected %@, got %@", self.outputCompanion.outputCode, code);
#ifdef WITH_UIKIT
			showWarningAlert(@"Received unexpected QR-code");
#else
            NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: received unexpected QR-code."
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"Expected value was %@, received %@.\nConsult Helpfile if this error persists.",
                              self.outputCompanion.outputCode, code];
            [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
#endif
            [self.outputCompanion triggerNewOutputValue];
        }
        self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
        self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
        [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
    }
}

///
/// This version of newInputDone is used when running in slave mode, it signals that the camera
/// has captured an input.
///
- (void) newInputDone: (void*)buffer width: (int)w height: (int)h format: (const char*)formatStr size: (int)size
{
    @synchronized(self) {
        assert(handlesInput);
        if (tsFrameLatest == 0) {
            NSLog(@"newInputDone called, but tsFrameLatest==0\n");
			assert(0);
            return;
        }

		assert(self.finder);
        uint64_t finderStartTime = [self.clock now];
        char *ccode = [self.finder find: buffer width: w height: h format: formatStr size:size];
        uint64_t finderStopTime = [self.clock now];
        uint64_t finderDuration = finderStopTime - finderStartTime;
        BOOL foundQRcode = (ccode != NULL);
        if (foundQRcode) {
			NSString *code = [NSString stringWithUTF8String: ccode];

            if (prevInputCode && [code isEqualToString: prevInputCode]) {
                // We have seen this code before. Only increment the detection count.
                prevInputCodeDetectionCount++;
				if (VL_DEBUG) NSLog(@"Found %d copies since %lld (%lld) of %@", prevInputCodeDetectionCount, tsLastReported, tsLastReportedRemote, prevInputCode);
            } else {
                // We found a new QR code (at least, different from the last detection).
                // Remember when we first detected it, and then see what we should do with it.
                prevInputCode = code;
                prevInputCodeDetectionCount = 1;
				uint64_t oldestTimePossible = tsFrameEarliest;
				if (oldestTimePossible == 0) oldestTimePossible = tsFrameLatest;
				tsLastReported = (oldestTimePossible + tsFrameLatest) / 2;
				tsLastReportedRemote = [self.remoteClock remoteNow:tsLastReported];
                VL_LOG_EVENT(@"slaveDetectionSlaveTime", tsLastReported, code);
                VL_LOG_EVENT(@"slaveDetectionMasterTime", tsLastReportedRemote, code);
                if (VL_DEBUG) NSLog(@"Found QR-code: %@", code);
                
                // If it is a URL it is probably a prerun QR-code (which is a URL, so that if
                // the receiver isn't running videoLat but an ordinary QR-code app they will be sent
                // to the website where they can download videoLat).
                // The prerun QR-code contains contact information for the server running on the
                // master copy of videoLat.
				if ([code hasPrefix:@"http:"]) {
                    NSURLComponents *urlComps = [NSURLComponents componentsWithString: code];
					assert(!self.protocol);	// If multiple different prearm codes are sent by the master this needs to be revisited
					assert(deviceDescriptorToSend); // Or could this be set at initialization?
					if ([urlComps.path isEqualToString: @"/landing"] && self.protocol == nil) {
						NSString *query = urlComps.query;
						NSLog(@"Server info: %@", query);
                        const char *cQuery = [query UTF8String];
                        char ipBuffer[128];
                        int port;
                        int rv = sscanf(cQuery, "ip=%126[^&]&port=%d", ipBuffer, &port);
                        if (rv != 2) {
                            [self _updateStatus: [NSString stringWithFormat: @"Unexcepted URL: %@", code] ];
                        } else {
                            NSString *ipAddress = [NSString stringWithUTF8String:ipBuffer];
#ifdef WITH_UIKIT
							dispatch_async(dispatch_get_main_queue(), ^{
								self.outputView.bPeerIPAddress.text = ipAddress;
								self.outputView.bPeerPort.text = [NSString stringWithFormat:@"%d", port];
								self.outputView.bPeerStatus.text = @"Connecting...";
							});

#else
                            self.outputView.bPeerIPAddress.stringValue = ipAddress;
                            self.outputView.bPeerPort.intValue = port;
                            self.outputView.bPeerStatus.stringValue = @"Connecting...";
#endif

                            self.protocol = [[NetworkProtocolClient alloc] initWithPort:port host: ipAddress];
							NSString *status;
                            if (self.protocol == nil) {
                                status = @"Failed to connect";
                            } else {
                                self.protocol.delegate = self;
                                status = @"Connection established";
                            }
#ifdef WITH_UIKIT
							dispatch_async(dispatch_get_main_queue(), ^{
								self.outputView.bPeerStatus.text = status;
							});
#else
                                self.outputView.bPeerStatus.stringValue = status;
#endif
                        }
					}
				}
                
            }
            // All QR codes are sent back to the master, assuming we have a connection to the master already.
            if (self.protocol) {
                uint64_t now = [self.clock now];
                uint64_t remoteNow = [self.remoteClock remoteNow: now];
                uint64_t rtt = [self.remoteClock rtt];
                NSMutableDictionary *msg = [@{
                                      @"code" : code,
                                      @"masterDetectTime": [NSString stringWithFormat:@"%lld", tsLastReportedRemote],
                                      @"slaveTime" : [NSString stringWithFormat:@"%lld", now],
                                      @"masterTime" : [NSString stringWithFormat:@"%lld", remoteNow],
                                      @"count" : [NSString stringWithFormat:@"%d", prevInputCodeDetectionCount],
                                      @"rtt" : [NSString stringWithFormat:@"%lld", rtt]
                                      } mutableCopy];
				if (deviceDescriptorToSend) {
                    NSData *ddData = [NSKeyedArchiver archivedDataWithRootObject: deviceDescriptorToSend];
                    assert(ddData);
                    NSString *ddString = [ddData base64EncodedStringWithOptions:0];
                    assert(ddString);
					[msg setObject: ddString forKey:@"inputDeviceDescriptor"];
					deviceDescriptorToSend = nil;
				}
				if (statusToPeer) {
					[msg setObject: statusToPeer forKey: @"peerStatus"];
					statusToPeer = nil;
				}
                [self.protocol send: msg];
                lastMessageSentTime = now;
            }
        } else {
             // No QR-code detected. Send a heartbeat every second.
            uint64_t now = [self.clock now];
            if (self.protocol && now - lastMessageSentTime > HEARTBEAT_INTERVAL) {
                uint64_t remoteNow = [self.remoteClock remoteNow: now];
                uint64_t rtt = [self.remoteClock rtt];
                NSMutableDictionary *msg = [@{
                                      @"slaveTime" : [NSString stringWithFormat:@"%lld", now],
                                      @"masterTime" : [NSString stringWithFormat:@"%lld", remoteNow],
                                      @"rtt" : [NSString stringWithFormat:@"%lld", rtt]
                                      } mutableCopy];
				if (deviceDescriptorToSend) {
                    NSData *ddData = [NSKeyedArchiver archivedDataWithRootObject: deviceDescriptorToSend];
                    assert(ddData);
                    NSString *ddString = [ddData base64EncodedStringWithOptions:0];
                    assert(ddString);
                    [msg setObject: ddString forKey:@"inputDeviceDescriptor"];
                    deviceDescriptorToSend = nil;
				}
				if (statusToPeer) {
					[msg setObject: statusToPeer forKey: @"peerStatus"];
					statusToPeer = nil;
				}
                [self.protocol send: msg];
                lastMessageSentTime = now;
            }
        }
#ifndef WITH_MEDIAN_TIMESTAMP
        inputStartTime = 0;
#endif
    }
}

- (void)newInputDone: (void*)buffer
                size: (int)size
            channels: (int)channels
                  at: (uint64_t)timestamp
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newInputDone in subclass"];
}

- (void)received:(NSDictionary *)data from: (id)connection
{
	if (!didReceiveData) {
		[self _updateStatus: @"Connected"];
		didReceiveData = YES;
	}
    if (!self.protocol) {
        NSLog(@"NetworkRunManager: discarding data received after connection close");
        return;
    }
    if (handlesOutput) {
        // This code runs in the slave (video receiver, network transmitter)
        assert(self.outputView);
        
        // Let's first check whether this message has the results, in that case we display them and are done.
        NSString *mrString = [data objectForKey: @"measurementResults"];
        if (mrString) {
            NSData *mrData = [[NSData alloc] initWithBase64EncodedString:mrString options:NSDataBase64DecodingIgnoreUnknownCharacters];
            assert(mrData);
            MeasurementDataStore *mr = [NSKeyedUnarchiver unarchiveObjectWithData:mrData];
            assert(mr);
            //
            // Override description with our description
            //
            mr.measurementType = self.measurementType.name;
            [self.protocol close];
            self.protocol = nil;
            if (self.capturer) [self.capturer stop];
            [self _updateStatus:@"Complete"];
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
			return;
        }
        //NSLog(@"received %@ from %@ (our protocol %@)", data, connection, self.protocol);
        uint64_t slaveTimestamp = getTimestamp(data, @"lastSlaveTime");
        uint64_t masterTimestamp = getTimestamp(data, @"lastMasterTime");
        if (slaveTimestamp && masterTimestamp) {
            uint64_t now = [self.clock now];
            [self.remoteClock remote:masterTimestamp between:slaveTimestamp and:now];
#ifdef WITH_UIKIT
			dispatch_async(dispatch_get_main_queue(), ^{
				self.outputView.bPeerRTT.text = [NSString stringWithFormat:@"%lld", [self.remoteClock rtt]/1000];
				});
#else
            self.outputView.bPeerRTT.intValue = (int)([self.remoteClock rtt]/1000);
#endif
            //NSLog(@"master %lld in %lld..%lld (delta=%lld)", masterTimestamp, slaveTimestamp, now, [self.remoteClock rtt]);
        } else {
            NSLog(@"unexpected data from master: %@", data);
        }
		NSString *peerStatus = [data objectForKey:@"peerStatus"];
		if (peerStatus) {
			[self _updateStatus: peerStatus];
		}
		NSString *statusCount = [data objectForKey:@"statusCount"];
		NSString *statusAverage = [data objectForKey: @"statusAverage"];
		if (self.statusView && (statusCount || statusAverage)) {
			self.statusView.detectCount = statusCount;
			self.statusView.detectAverage = statusAverage;
			[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
		}
    } else {
        // This code runs in the master (video sender, network receiver)
#ifdef WITH_APPKIT
        assert(self.selectionView);
#endif

        uint64_t slaveTimestamp = getTimestamp(data, @"slaveTime");
        uint64_t masterTimestamp = getTimestamp(data, @"masterTime");
		uint64_t masterDetectionTimestamp = getTimestamp(data, @"masterDetectTime");
        uint64_t rtt = getTimestamp(data, @"rtt");
        NSString *code = [data objectForKey: @"code"];
        
        if (slaveTimestamp) {
            uint64_t now = [self.clock now];
            NSMutableDictionary *msg = [@{
                                  @"lastMasterTime": [NSString stringWithFormat:@"%lld", now],
                                  @"lastSlaveTime" : [NSString stringWithFormat:@"%lld", slaveTimestamp],
                                  } mutableCopy];
			if (statusToPeer) {
				[msg setObject: statusToPeer forKey: @"peerStatus"];
				statusToPeer = nil;
			}
			if (self.collector && self.collector.count) {
				[msg setObject: [NSString stringWithFormat: @"%d", self.collector.count] forKey: @"statusCount"];
				[msg setObject: [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0] forKey: @"statusAverage"];
			}
            [self.protocol send: msg];
        }
        
		// Let's see whether they transmitted the device descriptor
		NSString *ddString = [data objectForKey: @"inputDeviceDescriptor"];
		if (ddString) {
            NSData *ddData = [[NSData alloc] initWithBase64EncodedString:ddString options:0];
            assert(ddData);
            DeviceDescription *dd = [NSKeyedUnarchiver unarchiveObjectWithData:ddData];
            assert(dd);
            if (remoteDevice) {
                // This should probably be an alert.
                NSLog(@"Received second remote device descriptor %@", dd);
            }
			remoteDevice = dd;
		}
		// And update our status, if needed
		NSString *peerStatus = [data objectForKey:@"peerStatus"];
		if (peerStatus) {
			[self _updateStatus: peerStatus];
		}

        if (rtt) {
            if (rtt > 10000000) {
                // RTT bigger than 10 seconds is preposterous
                NSLog(@"NetworkRunManager: preposterous RTT of %lld ms",(rtt/1000));
            }
#ifdef WITH_UIKIT
			dispatch_async(dispatch_get_main_queue(), ^{
				self.selectionViewForStatusOnly.bRTT.text = [NSString stringWithFormat:@"%lld", rtt/1000];
				});
#else
            self.selectionViewForStatusOnly.bRTT.intValue = (int)(rtt/1000);
#endif
        }
        
        if(code && masterDetectionTimestamp) {
			uint64_t count = getTimestamp(data, @"count");
            [self newInputDone: code count: (int)count at: masterDetectionTimestamp];
        } else if (code && self.preRunning) {
			uint64_t count = getTimestamp(data, @"count");
            [self newInputDone: code count: (int)count at: 0];
		} else {
            if (VL_DEBUG) NSLog(@"NetworkRunManager: received no qr-code at %lld,code=%@,masterDetectionTimestamp=%lld", masterTimestamp,code, masterDetectionTimestamp);
            [self newInputDoneNoData];
        }
    }
}

- (void)disconnected:(id)connection
{
    NSLog(@"received disconnect from %@ (our protocol %@)", connection, self.protocol);
    self.protocol = nil;
	[self _updateStatus: @"Disconnected"];
    if (self.preRunning)
        [self stopPreMeasuring: self];

}

- (NSString *)genPrerunCode
{
    assert (self.protocol);
    if (prerunCode == nil) {
        prerunCode = [NSString stringWithFormat:@"http://videolat.org/landing?ip=%@&port=%d", self.protocol.host, self.protocol.port];
    }
    return prerunCode;
}

- (IBAction)startPreMeasuring: (id)sender
{
    @synchronized(self) {
		[self _updateStatus: @"Determining RTT"];
		statusToPeer = @"Determining RTT";
        assert(handlesInput);
#ifdef WITH_APPKIT
        [self.selectionView.bPreRun setEnabled: NO];
#endif
        [self.statusView.bRun setEnabled: NO];
        if (self.statusView) {
            [self.statusView.bStop setEnabled: NO];
        }
        // Do actual prerunning
//        prerunMoreNeeded = PRERUN_COUNT;
        if (!handlesOutput) {
            BOOL ok = [self.outputCompanion companionStartPreMeasuring];
            if (!ok) return;
        }
        self.preRunning = YES;
        [self.outputCompanion triggerNewOutputValue];
    }
}

- (IBAction)stopPreMeasuring: (id)sender
{
    @synchronized(self) {
        assert(handlesInput);
        self.preRunning = NO;
        if (!handlesOutput)
            [self.outputCompanion companionStopPreMeasuring];
//        outputLevel = 0.5;
//        newOutputValueWanted = NO;
#ifdef WITH_APPKIT
        [self.selectionView.bPreRun setEnabled: NO];
#endif
        [self.statusView.bRun setEnabled: NO];
        //
        // We should now have the correct output device (locally) and input device (received from remote)
        NSString *errorMessage = nil;
        MeasurementDataStore *baseStore = nil;
        if (!self.measurementType.isCalibration) {
            // If this is not a calibration we should check our base type
            if (self.selectionView) baseName = [self.selectionView baseName];
            MeasurementType *baseType = self.measurementType.requires;
            baseStore = [baseType measurementNamed: baseName];
            if (baseType == nil) {
                errorMessage = @"No base (calibration) measurement selected.";
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
        if (errorMessage == nil && remoteDevice == nil) {
            errorMessage = @"No device description received from remote (slave) partner.";
        }
        if (errorMessage) {
			[self _updateStatus: @"Missing calibration"];
			statusToPeer = @"Missing calibration";
#ifdef WITH_UIKIT
			showWarningAlert(@"Base calibration mismatch");
#else
            NSAlert *alert = [NSAlert alertWithMessageText: @"Base calibration mismatch, are you sure you want to continue?"
                                             defaultButton:@"Cancel"
                                           alternateButton:@"Continue"
                                               otherButton:nil
                                 informativeTextWithFormat:@"%@", errorMessage];
            NSInteger button = [alert runModal];
            if (button == NSAlertDefaultReturn)
                return;
#endif
	   }
        // Remember the input and output device in the collector
        if (baseStore) {
            [self.collector.dataStore useOutputCalibration:baseStore];
        } else {
            self.collector.dataStore.output = [[DeviceDescription alloc] initFromOutputDevice: self.outputCompanion.outputView];
        }
        self.collector.dataStore.input = remoteDevice;

		[self _updateStatus: @"Ready to run"];
		statusToPeer = @"Ready to run";

        [self.statusView.bRun setEnabled: YES];
        if (!self.statusView) {
            // XXXJACK Make sure statusview is active/visible
        }
        [self.statusView.bStop setEnabled: NO];
        [self.outputCompanion triggerNewOutputValue];
    }
}

- (IBAction)startMeasuring: (id)sender
{
    @synchronized(self) {
		[self _updateStatus: @"Running measurements"];
		statusToPeer = @"Running measurements";
#ifdef WITH_APPKIT
        [self.selectionView.bPreRun setEnabled: NO];
#endif
        [self.statusView.bRun setEnabled: NO];
        if (!self.statusView) {
            // XXXJACK Make sure statusview is active/visible
        }
        [self.statusView.bStop setEnabled: YES];
        self.running = YES;
        if (!handlesOutput)
            [self.outputCompanion companionStartMeasuring];
        [self.collector startCollecting: self.measurementType.name];
        [self.outputCompanion triggerNewOutputValue];
    }
}

@end
