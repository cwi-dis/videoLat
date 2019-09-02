#import "NetworkIODevice.h"
#import "NetworkOutputView.h"
#import "EventLogger.h"
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <mach/clock.h>

#ifdef WITH_UIKIT
// Gross....
#define stringValue text
#endif

///
/// How often do we send a message if we have not received a QR-code (in microseconds)?
/// This define is used on the slave side, it keeps the connection open and the RTT clock difference.
/// In addition, it will trigger the master side to emit a fresh QR code if the current QR code hasn't been
/// detected for some time.
#define HEARTBEAT_INTERVAL 1000000LL

///
/// Helper function: get an uint64_t from a dictionary item, if it exists
static uint64_t getTimestamp(NSDictionary *data, NSString *key)
{
    id timeObject = [data objectForKey: key];
    if (timeObject == nil) {
        NSLog(@"No key %@ in received dictionary", key);
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

@implementation NetworkIODevice

- (NetworkIODevice *)init
{
    self = [super init];
    if (self) {
        self.remoteInputDeviceDescription = nil;
        self.remoteOutputDeviceDescription = nil;
        isServer = NO;
        isHelper = NO;
        didReceiveData = NO;
        connected = NO;
        remoteClock = [[RemoteClock alloc] init];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    assert(self.manager);
    if (self.clock == nil) self.clock = self;
}

- (void)dealloc
{
    [self stop];
    if (self.protocol) {
        [self.protocol close];
        self.protocol.delegate = nil;
    }
    self.protocol = nil;
}

- (uint64_t)now
{
    UInt64 timestamp;
    timestamp = monotonicMicroSecondClock();
    return timestamp;
}

- (BOOL)available {
	return connected;
}

- (NSArray *)deviceNames
{
    return @[];
}

- (NSString *)deviceID
{
    return @"NetworkInput";
}

- (NSString *)deviceName
{
    return @"NetworkInput";
}

- (BOOL)switchToDeviceWithName:(NSString *)name
{
	assert([name isEqualToString:@"NetworkInput"]);
    return true;
}

- (void) pauseCapturing:(BOOL)pause
{
}

- (void) startCapturing: (BOOL) showPreview
{
//	capturing = YES;
}

- (void) stopCapturing
{
//	capturing = NO;
}

- (void)setMinCaptureInterval: (uint64_t)interval
{
}

- (void) restart
{
}

- (void) stop
{
}

- (NSString *)genPrepareCode
{
    if (!self.protocol) return nil;
    // If we are already connected we don't need to return a connectable code
    if (connected) return nil;
    // If we are not connected we generate a new URL=based connection code.
    if (prepareCode == nil) {
        prepareCode = [NSString stringWithFormat:@"https://videolat.org/landing?ip=%@&port=%d", self.protocol.host, self.protocol.port];
    }
    return prepareCode;
}



- (void)showNewData {
    requestTransmissionCode = [self.manager getNewOutputCode];
    [self reportHeartbeat];
}

#pragma mark NetworkProtocolDelegate

- (void)received:(NSDictionary *)data from: (id)connection
{
    if (!didReceiveData) {
        [self reportStatus: @"Connected"];
        didReceiveData = YES;
    }
    if (!self.protocol) {
        NSLog(@"NetworkRunManager: discarding data received after connection close");
        return;
    }
    BOOL fromMaster = ([data objectForKey: @"fromMaster"] != nil);
    if (fromMaster != isHelper) {
        // Both sides think they are master, or both sides think they are helper.
        if (fromMaster) {
            [self reportStatus: @"Both sides run as master"];
        } else {
            [self reportStatus: @"Both sides run as helper"];
        }
    }
    
    if (!isHelper) {
        // This code runs in the server (video receiver, network transmitter)
        
        // Let's first check whether this message has the results, in that case we display them and are done.
        NSString *mrString = [data objectForKey: @"measurementResults"];
        if (mrString) {
            NSData *mrData = [[NSData alloc] initWithBase64EncodedString:mrString options:NSDataBase64DecodingIgnoreUnknownCharacters];
            assert(mrData);
            MeasurementDataStore *mr = [NSKeyedUnarchiver unarchiveObjectWithData:mrData];
            assert(mr);
            [self reportStatus:@"Complete"];
            [self.protocol close];
            if (self.protocol) self.protocol.delegate = nil;
            self.protocol = nil;
            assert(0); // xxxjack this has to go somewhere...
            // [self.manager reportResultsToRemote: mr];
            //
            // Override description with our description
            //
            return;
        }
        //NSLog(@"received %@ from %@ (our protocol %@)", data, connection, self.protocol);
        uint64_t helperTimestamp = getTimestamp(data, @"lastSlaveTime");
        uint64_t masterTimestamp = getTimestamp(data, @"lastMasterTime");
        if (helperTimestamp && masterTimestamp) {
            uint64_t now = [self.clock now];
            [remoteClock remote:masterTimestamp between:helperTimestamp and:now];
            [self.networkStatusView reportRTT:[remoteClock rtt]/1000 best:[remoteClock clockInterval]];
        } else {
            NSLog(@"no timestamps yet from helper: %@", data);
        }
        NSString *peerStatus = [data objectForKey:@"peerStatus"];
        if (peerStatus) {
            [self reportStatus: peerStatus];
        }
        NSString *statusCount = [data objectForKey:@"statusCount"];
        NSString *statusAverage = [data objectForKey: @"statusAverage"];
        if (self.manager.statusView && (statusCount || statusAverage)) {
            self.manager.statusView.detectCount = statusCount;
            self.manager.statusView.detectAverage = statusAverage;
            [self.manager.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
        }
        NSString *requestTransmission = [data objectForKey: @"requestTransmission"];
        if (requestTransmission) {
            [self.manager codeRequestedByMaster:requestTransmission];
        }
        NSString *code = [data objectForKey: @"code"];
        if(code) {
            uint64_t count = getTimestamp(data, @"count");
            uint64_t masterDetectionTimestamp = getTimestamp(data, @"masterDetectTime");
            [self.manager newInputDone: code count: (int)count at: masterDetectionTimestamp];
        }
    } else {
        // This code runs in the master (video sender, network receiver)
#ifdef WITH_APPKIT
        if(!self.manager.selectionView) NSLog(@"Warning: NetworkrunManager has no selectionView");
#endif
        
        uint64_t helperTimestamp = getTimestamp(data, @"slaveTime");
        uint64_t masterTimestamp = getTimestamp(data, @"masterTime");
        uint64_t masterDetectionTimestamp = getTimestamp(data, @"masterDetectTime");
        uint64_t rtt = getTimestamp(data, @"rtt");
        uint64_t clockInterval = getTimestamp(data, @"clockInterval");
        NSString *code = [data objectForKey: @"code"];
        NSString *transmittedCode = [data objectForKey: @"transmittedCode"];

        if (helperTimestamp && masterTimestamp) {
            uint64_t now = [self.clock now];
            [remoteClock remote:helperTimestamp between:masterTimestamp and:now];
            [self.networkStatusView reportRTT:[remoteClock rtt]/1000 best:[remoteClock clockInterval]];
        } else {
            NSLog(@"no timestamps yet from helper: %@", data);
        }

        if (helperTimestamp) {
            uint64_t now = [self.clock now];
            NSMutableDictionary *msg = [@{
                                          @"lastMasterTime": [NSString stringWithFormat:@"%lld", now],
                                          @"lastSlaveTime" : [NSString stringWithFormat:@"%lld", helperTimestamp],
                                          } mutableCopy];
            if (statusToPeer) {
                [msg setObject: statusToPeer forKey: @"peerStatus"];
                statusToPeer = nil;
            }
            if (!isHelper)
                [msg setObject: @"YES" forKey: @"fromMaster"];
            if (self.manager.collector && self.manager.collector.count) {
                [msg setObject: [NSString stringWithFormat: @"%d", self.manager.collector.count] forKey: @"statusCount"];
                [msg setObject: [NSString stringWithFormat: @"%.3f ms ± %.3f", self.manager.collector.average / 1000.0, self.manager.collector.stddev / 1000.0] forKey: @"statusAverage"];
            }
            [self.protocol send: msg];
        }
        
        // Let's see whether they transmitted the input device descriptor
        NSString *ddString;
        ddString = [data objectForKey: @"inputDeviceDescriptor"];
        if (ddString) {
            NSData *ddData = [[NSData alloc] initWithBase64EncodedString:ddString options:0];
            assert(ddData);
            DeviceDescription *dd = [NSKeyedUnarchiver unarchiveObjectWithData:ddData];
            assert(dd);
            if (self.remoteInputDeviceDescription) {
                // This should probably be an alert.
                NSLog(@"Received second remote device descriptor %@", dd);
            }
            self.remoteInputDeviceDescription = dd;
        }
        // Let's see whether they transmitted the output device descriptor
        ddString = [data objectForKey: @"outputDeviceDescriptor"];
        if (ddString) {
            NSData *ddData = [[NSData alloc] initWithBase64EncodedString:ddString options:0];
            assert(ddData);
            DeviceDescription *dd = [NSKeyedUnarchiver unarchiveObjectWithData:ddData];
            assert(dd);
            if (self.remoteOutputDeviceDescription) {
                // This should probably be an alert.
                NSLog(@"Received second remote device descriptor %@", dd);
            }
            self.remoteOutputDeviceDescription = dd;
        }
        // And update our status, if needed
        NSString *peerStatus = [data objectForKey:@"peerStatus"];
        if (peerStatus) {
            [self reportStatus: peerStatus];
        }
        
        if (rtt) {
            if (rtt > 10000000) {
                // RTT bigger than 10 seconds is preposterous
                NSLog(@"NetworkRunManager: preposterous RTT of %lld ms",(rtt/1000));
            }
            [self.networkStatusView reportRTT: rtt best:(uint64_t)clockInterval];
        }

        if(code) {
            uint64_t count = getTimestamp(data, @"count");
            [self.manager newInputDone: code count: (int)count at: masterDetectionTimestamp];
        } else if(transmittedCode) {
            if (![transmittedCode isEqualToString:lastRequestTransmissionCode]) {
                NSLog(@"NetworkRunManager: received transmitted code %@ but expected %@", transmittedCode, lastRequestTransmissionCode);
                return;
            }
            lastRequestTransmissionCode = nil;
            uint64_t masterTransmitTime = getTimestamp(data, @"masterTransmitTime");
            [self.manager newOutputDoneAt: masterTransmitTime];
        } else {
            // xxxjack is this correct? Also for helper that is transmitter?
            if (VL_DEBUG) NSLog(@"NetworkRunManager: received no qr-code at %lld,code=%@,masterDetectionTimestamp=%lld", masterTimestamp,code, masterDetectionTimestamp);
            [self.manager newInputDone:@"nothing" count:0 at:0];
        }
    }
}

- (void)connected:(id)connection
{
    assert(!connected);
    connected = YES;
    assert(self.networkStatusView);
    [self.networkStatusView reportStatus: @"Connection established"];
    assert(self.manager);
    [self.manager performSelectorOnMainThread:@selector(restart) withObject:nil waitUntilDone:NO];
}

- (void)disconnected:(id)connection
{
    NSLog(@"received disconnect from %@ (our protocol %@)", connection, self.protocol);
    [self.protocol close];
    if (self.protocol) self.protocol.delegate = nil;
    self.protocol = nil;
    [self reportStatus: @"Disconnected"];
    [self.manager stop]; // xxxjack or is this too rigorous???
    
}

- (void)openServer: (BOOL)asHelper
{
    assert(self.protocol == nil);
    assert(self.networkStatusView);
    isServer = YES;
    isHelper = asHelper;
    self.protocol = [[NetworkProtocolServer alloc] init];
    self.protocol.delegate = self;
    
    [self.networkStatusView reportServer: self.protocol.host port: self.protocol.port isUs: YES];
    [self.networkStatusView reportStatus: @"Waiting for connection"];
}

- (void)openClient: (BOOL) asHelper url:(NSString *)url
{
    assert(self.protocol == nil);
    isHelper = asHelper;
    NSURLComponents *urlComps = [NSURLComponents componentsWithString: url];
    assert(inputDeviceDescriptorToSend||outputDeviceDescriptorToSend); // Or could this be set at initialization?
    if ([urlComps.path isEqualToString: @"/landing"] && self.protocol == nil) {
        NSString *query = urlComps.query;
        NSLog(@"Server info: %@", query);
        const char *cQuery = [query UTF8String];
        char ipBuffer[128];
        int port;
        int rv = sscanf(cQuery, "ip=%126[^&]&port=%d", ipBuffer, &port);
        if (rv != 2) {
            [self reportStatus: [NSString stringWithFormat: @"Unexcepted URL: %@", url] ];
        } else {
            NSString *ipAddress = [NSString stringWithUTF8String:ipBuffer];
            assert(self.networkStatusView);
            [self.networkStatusView reportServer: ipAddress port: port isUs: NO];
            [self.networkStatusView reportStatus: @"Connecting..."];
            self.protocol = [[NetworkProtocolClient alloc] initWithPort:port host: ipAddress];
            NSString *status;
            if (self.protocol == nil) {
                status = @"Failed to connect";
            } else {
                connected = YES;
                self.protocol.delegate = self;
                status = @"Connection established";
            }
            [self.networkStatusView reportStatus: status];
        }
    } else {
        NSLog(@"Unexpected URL: %@", url);
        [self.networkStatusView reportStatus: @"Unexpected URL"];
    }
}

- (void)reportResult: (MeasurementDataStore *)ds
{
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

- (void)reportReception: (NSString *)code count:(int)count at:(uint64_t)timestamp
{
    if (self.protocol == nil) return;
    VL_LOG_EVENT(@"slaveDetectionSlaveTime", timestamp, code);
    uint64_t timestampRemote = [remoteClock remoteNow:timestamp];
    VL_LOG_EVENT(@"slaveDetectionMasterTime", timestampRemote, code);
    uint64_t now = [self.clock now];
    uint64_t remoteNow = [remoteClock remoteNow: now];
    uint64_t rtt = [remoteClock rtt];
    uint64_t clockInterval = [remoteClock clockInterval];
    NSMutableDictionary *msg = [@{
                                  @"code" : code,
                                  @"masterDetectTime": [NSString stringWithFormat:@"%lld", timestampRemote],
                                  @"slaveTime" : [NSString stringWithFormat:@"%lld", now],
                                  @"masterTime" : [NSString stringWithFormat:@"%lld", remoteNow],
                                  @"count" : [NSString stringWithFormat:@"%d", count],
                                  @"rtt" : [NSString stringWithFormat:@"%lld", rtt],
                                  @"clockInterval" : [NSString stringWithFormat:@"%lld", clockInterval]
                                  } mutableCopy];
    if (inputDeviceDescriptorToSend) {
        NSData *ddData = [NSKeyedArchiver archivedDataWithRootObject: inputDeviceDescriptorToSend];
        assert(ddData);
        NSString *ddString = [ddData base64EncodedStringWithOptions:0];
        assert(ddString);
        [msg setObject: ddString forKey:@"inputDeviceDescriptor"];
        inputDeviceDescriptorToSend = nil;
    }
    if (outputDeviceDescriptorToSend) {
        NSData *ddData = [NSKeyedArchiver archivedDataWithRootObject: outputDeviceDescriptorToSend];
        assert(ddData);
        NSString *ddString = [ddData base64EncodedStringWithOptions:0];
        assert(ddString);
        [msg setObject: ddString forKey:@"outputDeviceDescriptor"];
        outputDeviceDescriptorToSend = nil;
    }
    if (statusToPeer) {
        [msg setObject: statusToPeer forKey: @"peerStatus"];
        statusToPeer = nil;
    }
    if (!isHelper)
        [msg setObject: @"YES" forKey: @"fromMaster"];
    [self.protocol send: msg];
    lastMessageSentTime = now;
}

- (void)reportTransmission: (NSString *)code at:(uint64_t)timestamp
{
    if (self.protocol == nil) return;
    VL_LOG_EVENT(@"slaveTransmissionSlaveTime", timestamp, code);
    uint64_t timestampRemote = [remoteClock remoteNow:timestamp];
    VL_LOG_EVENT(@"slaveTransmissionMasterTime", timestampRemote, code);
    uint64_t now = [self.clock now];
    uint64_t remoteNow = [remoteClock remoteNow: now];
    uint64_t rtt = [remoteClock rtt];
    uint64_t clockInterval = [remoteClock clockInterval];
    NSMutableDictionary *msg = [@{
                                  @"transmittedCode" : code,
                                  @"masterTransmitTime": [NSString stringWithFormat:@"%lld", timestampRemote],
                                  @"slaveTime" : [NSString stringWithFormat:@"%lld", now],
                                  @"masterTime" : [NSString stringWithFormat:@"%lld", remoteNow],
                                  @"rtt" : [NSString stringWithFormat:@"%lld", rtt],
                                  @"clockInterval" : [NSString stringWithFormat:@"%lld", clockInterval]
                                  } mutableCopy];
    if (inputDeviceDescriptorToSend) {
        NSData *ddData = [NSKeyedArchiver archivedDataWithRootObject: inputDeviceDescriptorToSend];
        assert(ddData);
        NSString *ddString = [ddData base64EncodedStringWithOptions:0];
        assert(ddString);
        [msg setObject: ddString forKey:@"inputDeviceDescriptor"];
        inputDeviceDescriptorToSend = nil;
    }
    if (outputDeviceDescriptorToSend) {
        NSData *ddData = [NSKeyedArchiver archivedDataWithRootObject: outputDeviceDescriptorToSend];
        assert(ddData);
        NSString *ddString = [ddData base64EncodedStringWithOptions:0];
        assert(ddString);
        [msg setObject: ddString forKey:@"outputDeviceDescriptor"];
        outputDeviceDescriptorToSend = nil;
    }
    if (statusToPeer) {
        [msg setObject: statusToPeer forKey: @"peerStatus"];
        statusToPeer = nil;
    }
    if (!isHelper)
        [msg setObject: @"YES" forKey: @"fromMaster"];
    [self.protocol send: msg];
    lastMessageSentTime = now;
}

- (void)reportHeartbeat
{
    if (self.protocol == nil) return;
    uint64_t now = [self.clock now];
    if (now - lastMessageSentTime < HEARTBEAT_INTERVAL) return;
    uint64_t remoteNow = [remoteClock remoteNow: now];
    uint64_t rtt = [remoteClock rtt];
    uint64_t clockInterval = [remoteClock clockInterval];
    NSMutableDictionary *msg = [@{
                                  @"slaveTime" : [NSString stringWithFormat:@"%lld", now],
                                  @"masterTime" : [NSString stringWithFormat:@"%lld", remoteNow],
                                  @"rtt" : [NSString stringWithFormat:@"%lld", rtt],
                                  @"clockInterval" : [NSString stringWithFormat:@"%lld", clockInterval]
                                  } mutableCopy];
    if (inputDeviceDescriptorToSend) {
        NSData *ddData = [NSKeyedArchiver archivedDataWithRootObject: inputDeviceDescriptorToSend];
        assert(ddData);
        NSString *ddString = [ddData base64EncodedStringWithOptions:0];
        assert(ddString);
        [msg setObject: ddString forKey:@"inputDeviceDescriptor"];
        inputDeviceDescriptorToSend = nil;
    }
    if (outputDeviceDescriptorToSend) {
        NSData *ddData = [NSKeyedArchiver archivedDataWithRootObject: inputDeviceDescriptorToSend];
        assert(ddData);
        NSString *ddString = [ddData base64EncodedStringWithOptions:0];
        assert(ddString);
        [msg setObject: ddString forKey:@"inputDeviceDescriptor"];
        outputDeviceDescriptorToSend = nil;
    }
    if (requestTransmissionCode) {
        [msg setObject: requestTransmissionCode forKey: @"requestTransmission"];
        lastRequestTransmissionCode = requestTransmissionCode;
    }
    if (statusToPeer) {
        [msg setObject: statusToPeer forKey: @"peerStatus"];
        statusToPeer = nil;
    }
    if (!isHelper)
        [msg setObject: @"YES" forKey: @"fromMaster"];
    [self.protocol send: msg];
    lastMessageSentTime = now;
}

- (void)reportStatus: (NSString *)status
{
    statusToPeer = status;
    assert(self.networkStatusView);
    [self.networkStatusView reportStatus: status];
}

- (void)reportInputDevice: (DeviceDescription *)descr
{
    inputDeviceDescriptorToSend = descr;
}

- (void)reportOutputDevice: (DeviceDescription *)descr
{
    outputDeviceDescriptorToSend = descr;
}
@end
