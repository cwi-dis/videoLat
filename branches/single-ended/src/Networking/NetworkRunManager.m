//
//  NetworkRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "NetworkRunManager.h"

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
    rtt = finish-start;
	uint64_t mid = (finish+start)/2;
	localTimeToRemoteTime = (int64_t)remote - (int64_t)mid;
    initialized = true;
}

- (uint64_t) rtt
{
    return rtt;
}

@end

@implementation NetworkRunManager

+ (void)initialize
{
    // Unsure whether we need to register our class?
#if 0
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Networking"];
    // No nib is registered...
#endif
    // We register ourselves for receive-only, as a slave. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Reception (Slave/Client)"];
    [BaseRunManager registerNib: @"SlaveReceiverRun" forMeasurementType: @"Video Reception (Slave/Client)"];
}

- (NetworkRunManager *) init
{
    self = [super init];
    if (self) {
        handlesInput = NO;
        handlesOutput = NO;
    }
    return self;
}

- (void) awakeFromNib
{
    NSString *errorMessage = nil;
    handlesInput = self.inputCompanion == nil;
    handlesOutput = self.outputCompanion == nil;
    if (handlesInput && handlesOutput) {
        // This run manager is responsible for both input and output
        self.inputCompanion = self;
        self.outputCompanion = self;
    }
    if (handlesInput) {
        // We handle only input. Assert output handler exists and points back to us
        if (self.outputCompanion.inputCompanion != self) {
            errorMessage = [NSString stringWithFormat:@"Programmer error: %@ has outputCompanion %@ but it has inputCompanion %@",
                            self, self.outputCompanion, self.outputCompanion.inputCompanion];
        }
    }
    if (handlesOutput) {
        // We handle only output. Assert input handler exists and points back to us
        if (self.inputCompanion.outputCompanion != self) {
            errorMessage = [NSString stringWithFormat:@"Programmer error: %@ has inputCompanion %@ but it has outputCompanion %@",
                            self, self.inputCompanion, self.inputCompanion.outputCompanion];
        }
    }
    if (errorMessage) {
        NSAlert *alert = [NSAlert alertWithMessageText: @"Internal error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", errorMessage];
        [alert runModal];
    }
    // If we don't handle output (i.e. output is going through video) we start the server and
    // report the port number
    if (!handlesOutput) {
        assert(self.protocol == nil);
        self.protocol = [[NetworkProtocolServer alloc] init];
        self.protocol.delegate = self;
        self.selectionView.bOurPort.intValue = self.protocol.port;
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


#if 0

- (void)terminate
{
	BaseRunManager *ic = self.inputCompanion, *oc = self.outputCompanion;
	self.inputCompanion = nil;
	self.outputCompanion = nil;
	if (ic) [ic terminate];
	if (oc) [oc terminate];
	self.collector = nil;
	self.statusView = nil;
	self.measurementMaster = nil;
	
}

- (void) dealloc
{
}


- (void) selectMeasurementType:(NSString *)typeName
{
	measurementType = [MeasurementType forType:typeName];
    if (self.outputCompanion && self.outputCompanion != self)
        [self.outputCompanion selectMeasurementType: typeName];
    [self restart];
}
#endif

- (void)restart
{
    NSLog(@"NetworkRunManager.restart. Unsure what to do...");
    [self.capturer startCapturing: YES];
}

- (void)stop
{
	//[NSException raise:@"NetworkRunManager" format:@"Must override stop in subclass"];
    NSLog(@"NetworkRunManager.stop. Unsure what to do...");
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

- (void)setFinderRect: (NSRect)theRect
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
        inputStartTime = timestamp;
        
        // Sanity check: times should be monotonically increasing
        if (prevInputStartTime && prevInputStartTime >= inputStartTime) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: input clock not monotonically increasing."
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"Previous value was %lld, current value is %lld.\nConsult Helpfile if this error persists.",
                              (long long)prevInputStartTime,
                              (long long)inputStartTime];
            [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
        }
    }
}


- (void)newInputDone
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newInputDone in subclass"];
}
///
/// This version of newInputDone is used when running in master mode, it signals a reception
/// by the network module
///
- (void) newInputDone: (NSString *)data count: (int)count at: (uint64_t) timeStamp
{
}

///
/// This version of newInputDone is used when running in slave mode, it signals that the camera
/// has captured an input.
///
- (void) newInputDone: (void*)buffer width: (int)w height: (int)h format: (const char*)formatStr size: (int)size
{
    @synchronized(self) {
        assert(handlesInput);
        if (inputStartTime == 0) {
            NSLog(@"newInputDone called, but inputStartTime==0\n");
            return;
        }

		assert(self.finder);
        char *ccode = [self.finder find: buffer width: w height: h format: formatStr size:size];
        BOOL foundQRcode = (ccode != NULL);
        if (foundQRcode) {
			NSString *code = [NSString stringWithUTF8String: ccode];

            if (prevInputCode && [code isEqualToString: prevInputCode]) {
                // We have seen this code before. Only increment the detection count.
                prevInputCodeDetectionCount++;
				//NSLog(@"Found %d copies since %lld (%lld) of %@", prevInputCodeDetectionCount, prevInputStartTime, prevInputStartTimeRemote, prevInputCode);
            } else {
                // We found a new QR code (at least, different from the last detection).
                // Remember when we first detected it, and then see what we should do with it.
                prevInputCode = code;
                prevInputCodeDetectionCount = 1;
                prevInputStartTime = inputStartTime;
				prevInputStartTimeRemote = [self.remoteClock remoteNow:prevInputStartTime];
                NSLog(@"Found QR-code: %@", code);
                
                // If it is a URL it is probably a prerun QR-code (which is a URL, so that if
                // the receiver isn't running videoLat but an ordinary QR-code app they will be sent
                // to the website where they can download videoLat).
                // The prerun QR-code contains contact information for the server running on the
                // master copy of videoLat.
				NSURLComponents *urlComps = [NSURLComponents componentsWithString: code];
				if (urlComps) {
					if ([urlComps.path isEqualToString: @"/landing"] && self.protocol == nil) {
						NSString *query = urlComps.query;
						NSLog(@"Server info: %@", query);
                        const char *cQuery = [query UTF8String];
                        char ipBuffer[128];
                        int port;
                        int rv = sscanf(cQuery, "ip=%126[^&]&port=%d", ipBuffer, &port);
                        if (rv != 2) {
                            self.outputView.bPeerStatus.stringValue = [NSString stringWithFormat: @"Unexcepted URL: %@", code];
                        } else {
                            NSString *ipAddress = [NSString stringWithUTF8String:ipBuffer];
                            self.outputView.bPeerIPAddress.stringValue = ipAddress;
                            self.outputView.bPeerPort.intValue = port;
                            self.outputView.bPeerStatus.stringValue = @"Connecting...";
                            
                            self.protocol = [[NetworkProtocolClient alloc] initWithPort:port host: ipAddress];
                            if (self.protocol == nil) {
                                self.outputView.bPeerStatus.stringValue = @"Failed to connect";
                            } else {
                                self.protocol.delegate = self;
                                self.outputView.bPeerStatus.stringValue = @"Connected";
                            }
                        }
					}
				}
                
#if 0
                // Let's first report it.
                if (self.running) {
                    BOOL ok = [self.collector recordReception: self.outputCompanion.outputCode at: inputStartTime];
                    if (!ok) {
                        NSAlert *alert = [NSAlert alertWithMessageText:@"Reception before transmission."
                                                         defaultButton:@"OK"
                                                       alternateButton:nil
                                                           otherButton:nil
                                             informativeTextWithFormat:@"Code %@ was transmitted at %lld, but received at %lld.\nConsult Helpfile if this error persists.",
                                          self.outputCompanion.outputCode,
                                          (long long)prerunOutputStartTime,
                                          (long long)inputStartTime];
                        [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
                    }
                } else if (self.preRunning) {
                    [self _prerunRecordReception: self.outputCompanion.outputCode];
                }
                // Now do a sanity check that it is greater than the previous detected code
                if (prevInputCode && [prevInputCode length] >= [self.outputCompanion.outputCode length] && [prevInputCode compare:self.outputCompanion.outputCode] >= 0) {
                    NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: input QR-code not monotonically increasing."
                                                     defaultButton:@"OK"
                                                   alternateButton:nil
                                                       otherButton:nil
                                         informativeTextWithFormat:@"Previous value was %@, current value is %@.\nConsult Helpfile if this error persists.",
                                      prevInputCode, self.outputCompanion.outputCode];
                    [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
                }
                // Now let's remember it so we don't generate "bad code" messages
                // if we detect it a second time.
#endif
            }
            // All QR codes are sent back to the master, assuming we have a connection to the master already.
            if (self.protocol) {
                uint64_t now = [self.clock now];
                uint64_t remoteNow = [self.remoteClock remoteNow: now];
                uint64_t rtt = [self.remoteClock rtt];
                NSDictionary *msg = @{
                                      @"code" : code,
                                      @"masterDetectTime": [NSString stringWithFormat:@"%lld", prevInputStartTimeRemote],
                                      @"slaveTime" : [NSString stringWithFormat:@"%lld", now],
                                      @"masterTime" : [NSString stringWithFormat:@"%lld", remoteNow],
                                      @"count" : [NSString stringWithFormat:@"%d", prevInputCodeDetectionCount],
                                      @"rtt" : [NSString stringWithFormat:@"%lld", rtt]
                                      };
                [self.protocol send: msg];
            }
        }
        inputStartTime = 0;
#if 0
        if (self.running) {
            self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
            self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
            [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
        }
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
    if (handlesOutput) {
        // This code runs in the slave (video receiver, network transmitter)
        assert(self.outputView);
        //NSLog(@"received %@ from %@ (our protocol %@)", data, connection, self.protocol);
        uint64_t slaveTimestamp = getTimestamp(data, @"lastSlaveTime");
        uint64_t masterTimestamp = getTimestamp(data, @"lastMasterTime");
        if (slaveTimestamp && masterTimestamp) {
            uint64_t now = [self.clock now];
            [self.remoteClock remote:masterTimestamp between:slaveTimestamp and:now];
            self.outputView.bPeerRTT.intValue = (int)([self.remoteClock rtt]/1000);
            NSLog(@"master %lld in %lld..%lld (delta=%lld)", masterTimestamp, slaveTimestamp, now, [self.remoteClock rtt]);
        } else {
            NSLog(@"unexpected data from master: %@", data);
        }
    } else {
        // This code runs in the master (video sender, network receiver)
        assert(self.selectionView);
        self.selectionView.bOurStatus.stringValue = @"Connected";
        NSLog(@"received %@ from %@ (our protocol %@)", data, connection, self.protocol);
        
        uint64_t slaveTimestamp = getTimestamp(data, @"slaveTime");
        uint64_t masterTimestamp = getTimestamp(data, @"masterTime");
        uint64_t rtt = getTimestamp(data, @"rtt");
        uint64_t count = getTimestamp(data, @"count");
        NSString *code = [data objectForKey: @"code"];
        
        if (slaveTimestamp) {
            uint64_t now = [self.clock now];
            NSDictionary *msg = @{
                                  @"lastMasterTime": [NSString stringWithFormat:@"%lld", now],
                                  @"lastSlaveTime" : [NSString stringWithFormat:@"%lld", slaveTimestamp],
                                  };
            [self.protocol send: msg];
        }
        if (rtt) {
            self.selectionView.bRTT.intValue = (int)(rtt/1000);
        }
        
        if(code && masterTimestamp) {
            [self newInputDone: code count: (int)count at: masterTimestamp];
        }
    }
}

- (void)disconnected:(id)connection
{
    NSLog(@"received disconnect from %@ (our protocol %@)", connection, self.protocol);
    self.protocol = nil;
    if (self.outputView) {
        self.outputView.bPeerStatus.stringValue = @"Disconnected";
    }
    if (self.selectionView) {
        self.selectionView.bOurStatus.stringValue = @"Disconnected";
    }

}

- (NSString *)genPrerunCode
{
    assert (self.protocol);
    return [NSString stringWithFormat:@"http://videolat.org/landing?ip=%@&port=%d", self.protocol.host, self.protocol.port];
}

- (IBAction)startPreMeasuring: (id)sender
{
    @synchronized(self) {
        assert(handlesInput);
        [self.selectionView.bPreRun setEnabled: NO];
        [self.selectionView.bRun setEnabled: NO];
        if (self.statusView) {
            [self.statusView.bStop setEnabled: NO];
        }
        // Do actual prerunning
//        prerunMoreNeeded = PRERUN_COUNT;
        self.preRunning = YES;
        if (!handlesOutput)
            self.outputCompanion.preRunning = YES;
        [self.outputCompanion triggerNewOutputValue];
    }
}

- (IBAction)stopPreMeasuring: (id)sender
{
    @synchronized(self) {
        assert(handlesInput);
        self.preRunning = NO;
        if (!handlesOutput)
            self.outputCompanion.preRunning = NO;
//        outputLevel = 0.5;
//        newOutputValueWanted = NO;
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
        if (!handlesOutput)
            self.outputCompanion.running = YES;
//        [self.collector startCollecting: self.measurementType.name input: self.device.deviceID name: self.device.deviceName output: self.device.deviceID name: self.device.deviceName];
        [self.outputCompanion triggerNewOutputValue];
    }
}

@end
