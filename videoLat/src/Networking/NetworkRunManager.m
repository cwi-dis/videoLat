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

#ifdef WITH_UIKIT
// Gross....
#define stringValue text
#endif

///
/// How many times do we want to get a message that the prerun code has been detected?
/// This define is used on the master side, and stops the prerun sequence. It should be high enough that we
/// have a reasonable measurement of the RTT and the clock difference.
#define PREPARE_COUNT 32

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
	uint64_t clockInterval;
    uint64_t rtt;
    bool initialized;
};
- (uint64_t)remoteNow: (uint64_t) now;
- (void)remote: (uint64_t)remote between: (uint64_t)start and: (uint64_t) finish;
- (uint64_t)rtt;
- (uint64_t)clockInterval;
@end

/// Define this to always use the latest measurement as the correct time.
#undef WITH_TIMESYNC_LATEST
/// Define this to use the best measurement (shortest RTT) as the correct time.
#define WITH_TIMESYNC_BEST

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
	uint64_t newLocalTimeToRemoteTime = (int64_t)remote - (int64_t)mid;
#ifdef WITH_TIMESYNC_BEST
	if (rtt <= clockInterval || !initialized) {
		clockInterval = rtt;
		localTimeToRemoteTime = newLocalTimeToRemoteTime;
	}
#elif WITH_TIMESYNC_LATEST
	clockInterval = rtt;
	localTimeToRemoteTime = newLocalTimeToRemoteTime;
#else
#error No timesync algorithm selected
#endif
    VL_LOG_EVENT(@"NewMasterTime", [self remoteNow: finish], @"");
    initialized = true;
}

- (uint64_t) rtt
{
    return rtt;
}

- (uint64_t) clockInterval
{
    return clockInterval;
}

@end

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
    if (self.capturer && ![self.capturer isKindOfClass: [NetworkInput class]]) {
        slaveHandler = YES;
    }
    [super awakeFromNib];
    assert(self.clock);
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
        assert(self.protocol == nil);
        self.protocol = [[NetworkProtocolServer alloc] init];
        self.protocol.delegate = self;
        self.selectionViewForStatusOnly.bOurPort.stringValue = [NSString stringWithFormat:@"%@:%d", self.protocol.host, self.protocol.port];
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
    NetworkOutputView *nov = NULL;
    if ([self.outputView isKindOfClass:[NetworkOutputView class]]) {
        nov = (NetworkOutputView *)self.outputView;
    }
	dispatch_async(dispatch_get_main_queue(), ^{
		if (nov) {
			nov.bPeerStatus.stringValue = status;
		}
		if (self.selectionViewForStatusOnly) {
			self.selectionViewForStatusOnly.bOurStatus.stringValue = status;
		}
	});
}

- (IBAction)inputSelectionChanged:(id)sender
{
	assert(handlesInput);
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
		[self.capturer startCapturing:YES];
	}
	return YES;
}

- (void)stop
{
	self.running = NO;
	self.preparing = NO;
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
        [self.protocol close];
        self.protocol.delegate = nil;
        self.protocol = nil;
    }
}

- (void)triggerNewOutputValue
{
	[NSException raise:@"NetworkRunManager" format:@"Must override triggerNewOutputValue in subclass"];
    assert(handlesOutput);
}

- (CIImage *)getNewOutputImage
{
	[NSException raise:@"NetworkRunManager" format:@"Must override getNewOutputImage in subclass"];
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

- (void) newInputStart:(uint64_t)timestamp
{
    @synchronized(self) {
        assert(handlesInput);
		tsFrameEarliest = tsFrameLatest;
		tsFrameLatest = timestamp;

		// Sanity check: times should be monotonically increasing
		if (tsFrameEarliest >= tsFrameLatest) {
			showWarningAlert(@"Input clock has gone back in time");
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
    if (self.preparing) {
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

///
/// This version of newInputDone is used when running in slave mode, it signals that the camera
/// has captured an input.
///
- (void) newInputDone: (CVImageBufferRef)image
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
				if ([code hasPrefix:@"http"]) {
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
                            NetworkOutputView *nov = NULL;
                            if ([self.outputView isKindOfClass:[NetworkOutputView class]]) {
                                nov = (NetworkOutputView *)self.outputView;
                            }
                            NSString *ipAddress = [NSString stringWithUTF8String:ipBuffer];
							dispatch_async(dispatch_get_main_queue(), ^{
								nov.bPeerIPAddress.stringValue = ipAddress;
								nov.bPeerPort.stringValue = [NSString stringWithFormat:@"%d", port];
								nov.bPeerStatus.stringValue = @"Connecting...";
							});

                            self.protocol = [[NetworkProtocolClient alloc] initWithPort:port host: ipAddress];
							NSString *status;
                            if (self.protocol == nil) {
                                status = @"Failed to connect";
                            } else {
                                self.protocol.delegate = self;
                                status = @"Connection established";
                            }
							dispatch_async(dispatch_get_main_queue(), ^{
								nov.bPeerStatus.stringValue = status;
							});
                        }
					}
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
            if (self.protocol) {
                uint64_t now = [self.clock now];
                uint64_t remoteNow = [self.remoteClock remoteNow: now];
                uint64_t rtt = [self.remoteClock rtt];
				uint64_t clockInterval = [self.remoteClock clockInterval];
                NSMutableDictionary *msg = [@{
                                      @"code" : code,
                                      @"masterDetectTime": [NSString stringWithFormat:@"%lld", tsLastReportedRemote],
                                      @"slaveTime" : [NSString stringWithFormat:@"%lld", now],
                                      @"masterTime" : [NSString stringWithFormat:@"%lld", remoteNow],
                                      @"count" : [NSString stringWithFormat:@"%d", prevInputCodeDetectionCount],
                                      @"rtt" : [NSString stringWithFormat:@"%lld", rtt],
                                      @"clockInterval" : [NSString stringWithFormat:@"%lld", clockInterval]
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
				uint64_t clockInterval = [self.remoteClock clockInterval];
                NSMutableDictionary *msg = [@{
                                      @"slaveTime" : [NSString stringWithFormat:@"%lld", now],
                                      @"masterTime" : [NSString stringWithFormat:@"%lld", remoteNow],
                                      @"rtt" : [NSString stringWithFormat:@"%lld", rtt],
                                      @"clockInterval" : [NSString stringWithFormat:@"%lld", clockInterval]
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
            if (self.protocol) self.protocol.delegate = nil;
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
            if ([self.outputView isKindOfClass:[NetworkOutputView class]]) {
                NetworkOutputView *nov = (NetworkOutputView *)self.outputView;
                dispatch_async(dispatch_get_main_queue(), ^{
                    nov.bPeerRTT.stringValue = [NSString stringWithFormat:@"%lld (best %lld)", [self.remoteClock rtt]/1000, [self.remoteClock clockInterval]/1000];
                    });
            //NSLog(@"master %lld in %lld..%lld (delta=%lld)", masterTimestamp, slaveTimestamp, now, [self.remoteClock rtt]);
            }
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
        if(!self.selectionView) NSLog(@"Warning: NetworkrunManager has no selectionView");
#endif

        uint64_t slaveTimestamp = getTimestamp(data, @"slaveTime");
        uint64_t masterTimestamp = getTimestamp(data, @"masterTime");
		uint64_t masterDetectionTimestamp = getTimestamp(data, @"masterDetectTime");
        uint64_t rtt = getTimestamp(data, @"rtt");
        uint64_t clockInterval = getTimestamp(data, @"clockInterval");
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
			dispatch_async(dispatch_get_main_queue(), ^{
				self.selectionViewForStatusOnly.bRTT.stringValue = [NSString stringWithFormat:@"%lld (best %lld)", rtt/1000, clockInterval/1000];
				});
        }
        
        if(code && masterDetectionTimestamp) {
			uint64_t count = getTimestamp(data, @"count");
            [self newInputDone: code count: (int)count at: masterDetectionTimestamp];
        } else if (code && self.preparing) {
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
	[self.protocol close];
	if (self.protocol) self.protocol.delegate = nil;
	self.protocol = nil;
	[self _updateStatus: @"Disconnected"];
    if (self.preparing)
        [self performSelectorOnMainThread:@selector(stopPreMeasuring:) withObject:self waitUntilDone:NO];

}

- (NSString *)genPrepareCode
{
    assert (self.protocol);
    if (prepareCode == nil) {
        prepareCode = [NSString stringWithFormat:@"https://videolat.org/landing?ip=%@&port=%d", self.protocol.host, self.protocol.port];
    }
    return prepareCode;
}

- (IBAction)startPreMeasuring: (id)sender
{
    @synchronized(self) {
		[self _updateStatus: @"Determining RTT"];
		statusToPeer = @"Determining RTT";
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
        if (errorMessage == nil && remoteDevice == nil) {
            errorMessage = @"No device description received from remote (slave) partner.";
        }
        if (errorMessage) {
			[self _updateStatus: @"Missing calibration"];
			statusToPeer = @"Missing calibration";
			showWarningAlert(errorMessage);
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
		[self _updateStatus: @"Running measurements"];
		statusToPeer = @"Running measurements";
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
