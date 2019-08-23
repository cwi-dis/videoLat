#import "NetworkInput.h"
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

@implementation NetworkInput

- (NetworkInput *)init
{
    self = [super init];
    if (self) {
#if 0
        slaveHandler = NO;
        statusToPeer = nil;
#endif
        self.remoteDeviceDescription = nil;
        isClient = NO;
        isServer = NO;
        didReceiveData = NO;
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    assert(self.manager);
    if (self.outputManager == nil) self.outputManager = self.manager;
    if (self.clock == nil) self.clock = self;
}

- (void)dealloc
{
    [self stop];
}

- (uint64_t)now
{
    UInt64 timestamp;
    timestamp = monotonicMicroSecondClock();
    return timestamp;
}

- (BOOL)available {
	return YES; // xxxjack or should we test this?
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
    assert (self.protocol);
    if (prepareCode == nil) {
        prepareCode = [NSString stringWithFormat:@"https://videolat.org/landing?ip=%@&port=%d", self.protocol.host, self.protocol.port];
    }
    return prepareCode;
}

- (void)setOutputCode: (NSString *)newValue report: (BOOL)report
{
#if 0
    assert(alive);
    outputCode = newValue;
    newOutputValueWanted = YES;
    reportNewOutput = report;
#endif
}

#pragma mark NetworkProtocolDelegate

- (void)received:(NSDictionary *)data from: (id)connection
{
    if (!didReceiveData) {
        [self tmpUpdateStatus: @"Connected"];
        didReceiveData = YES;
    }
    if (!self.protocol) {
        NSLog(@"NetworkRunManager: discarding data received after connection close");
        return;
    }
    if (isServer) {
        // This code runs in the slave (video receiver, network transmitter)
        
        // Let's first check whether this message has the results, in that case we display them and are done.
        NSString *mrString = [data objectForKey: @"measurementResults"];
        if (mrString) {
            NSData *mrData = [[NSData alloc] initWithBase64EncodedString:mrString options:NSDataBase64DecodingIgnoreUnknownCharacters];
            assert(mrData);
            MeasurementDataStore *mr = [NSKeyedUnarchiver unarchiveObjectWithData:mrData];
            assert(mr);
            [self tmpUpdateStatus:@"Complete"];
            [self.protocol close];
            if (self.protocol) self.protocol.delegate = nil;
            self.protocol = nil;
            assert(0);
            // [self.manager reportRemoteResults: mr];
            //
            // Override description with our description
            //
            return;
        }
        //NSLog(@"received %@ from %@ (our protocol %@)", data, connection, self.protocol);
        uint64_t slaveTimestamp = getTimestamp(data, @"lastSlaveTime");
        uint64_t masterTimestamp = getTimestamp(data, @"lastMasterTime");
        if (slaveTimestamp && masterTimestamp) {
            uint64_t now = [self.clock now];
            [remoteClock remote:masterTimestamp between:slaveTimestamp and:now];
            if ([self.manager.outputView isKindOfClass:[NetworkOutputView class]]) {
                NetworkOutputView *nov = (NetworkOutputView *)self.manager.outputView;
                dispatch_async(dispatch_get_main_queue(), ^{
                    nov.bPeerRTT.stringValue = [NSString stringWithFormat:@"%lld (best %lld)", [self->remoteClock rtt]/1000, [self->remoteClock clockInterval]/1000];
                });
                //NSLog(@"master %lld in %lld..%lld (delta=%lld)", masterTimestamp, slaveTimestamp, now, [remoteClock rtt]);
            }
        } else {
            NSLog(@"unexpected data from master: %@", data);
        }
        NSString *peerStatus = [data objectForKey:@"peerStatus"];
        if (peerStatus) {
            [self tmpUpdateStatus: peerStatus];
        }
        NSString *statusCount = [data objectForKey:@"statusCount"];
        NSString *statusAverage = [data objectForKey: @"statusAverage"];
        if (self.manager.statusView && (statusCount || statusAverage)) {
            self.manager.statusView.detectCount = statusCount;
            self.manager.statusView.detectAverage = statusAverage;
            [self.manager.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
        }
    } else {
        // This code runs in the master (video sender, network receiver)
#ifdef WITH_APPKIT
        if(!self.manager.selectionView) NSLog(@"Warning: NetworkrunManager has no selectionView");
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
            if (self.manager.collector && self.manager.collector.count) {
                [msg setObject: [NSString stringWithFormat: @"%d", self.manager.collector.count] forKey: @"statusCount"];
                [msg setObject: [NSString stringWithFormat: @"%.3f ms ± %.3f", self.manager.collector.average / 1000.0, self.manager.collector.stddev / 1000.0] forKey: @"statusAverage"];
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
            if (self.remoteDeviceDescription) {
                // This should probably be an alert.
                NSLog(@"Received second remote device descriptor %@", dd);
            }
            self.remoteDeviceDescription = dd;
        }
        // And update our status, if needed
        NSString *peerStatus = [data objectForKey:@"peerStatus"];
        if (peerStatus) {
            [self tmpUpdateStatus: peerStatus];
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
        
        if(code) {
            uint64_t count = getTimestamp(data, @"count");
            [self.manager newInputDone: code count: (int)count at: masterDetectionTimestamp];
        } else {
            if (VL_DEBUG) NSLog(@"NetworkRunManager: received no qr-code at %lld,code=%@,masterDetectionTimestamp=%lld", masterTimestamp,code, masterDetectionTimestamp);
            [self.manager newInputDone:@"nothing" count:0 at:0];
        }
    }
}

- (void)disconnected:(id)connection
{
    NSLog(@"received disconnect from %@ (our protocol %@)", connection, self.protocol);
    [self.protocol close];
    if (self.protocol) self.protocol.delegate = nil;
    self.protocol = nil;
    [self tmpUpdateStatus: @"Disconnected"];
    [self.manager stop]; // xxxjack or is this too rigorous???
    
}

#pragma mark xxxjack temporary

- (void)tmpOpenServer
{
    assert(self.protocol == nil);
    isServer = YES;
    self.protocol = [[NetworkProtocolServer alloc] init];
    self.protocol.delegate = self;
    self.selectionViewForStatusOnly.bOurPort.stringValue = [NSString stringWithFormat:@"%@:%d", self.protocol.host, self.protocol.port];
}

- (void)tmpOpenClient: (NSString *)url
{
    assert(self.protocol == nil);
    isClient = YES;
    NSURLComponents *urlComps = [NSURLComponents componentsWithString: url];
    assert(deviceDescriptorToSend); // Or could this be set at initialization?
    if ([urlComps.path isEqualToString: @"/landing"] && self.protocol == nil) {
        NSString *query = urlComps.query;
        NSLog(@"Server info: %@", query);
        const char *cQuery = [query UTF8String];
        char ipBuffer[128];
        int port;
        int rv = sscanf(cQuery, "ip=%126[^&]&port=%d", ipBuffer, &port);
        if (rv != 2) {
            [self tmpUpdateStatus: [NSString stringWithFormat: @"Unexcepted URL: %@", url] ];
        } else {
            NetworkOutputView *nov = NULL;
            if ([self.manager.outputView isKindOfClass:[NetworkOutputView class]]) {
                nov = (NetworkOutputView *)self.manager.outputView;
            }
            NSString *ipAddress = [NSString stringWithUTF8String:ipBuffer];
            dispatch_async(dispatch_get_main_queue(), ^{
                nov.bPeerIPAddress.stringValue = ipAddress;
                nov.bPeerPort.stringValue = [NSString stringWithFormat:@"%d", port];
                nov.bNetworkStatus.stringValue = @"Connecting...";
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
                nov.bNetworkStatus.stringValue = status;
            });
        }
    }
}

- (void)tmpSendResult: (MeasurementDataStore *)ds
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

- (void)tmpReport: (NSString *)code count:(int)count at:(uint64_t)tsLastReported
{
    if (self.protocol == nil) return;
    VL_LOG_EVENT(@"slaveDetectionSlaveTime", tsLastReported, code);
    uint64_t tsLastReportedRemote = [remoteClock remoteNow:tsLastReported];
    VL_LOG_EVENT(@"slaveDetectionMasterTime", tsLastReportedRemote, code);
    uint64_t now = [self.clock now];
    uint64_t remoteNow = [remoteClock remoteNow: now];
    uint64_t rtt = [remoteClock rtt];
    uint64_t clockInterval = [remoteClock clockInterval];
    NSMutableDictionary *msg = [@{
                                  @"code" : code,
                                  @"masterDetectTime": [NSString stringWithFormat:@"%lld", tsLastReportedRemote],
                                  @"slaveTime" : [NSString stringWithFormat:@"%lld", now],
                                  @"masterTime" : [NSString stringWithFormat:@"%lld", remoteNow],
                                  @"count" : [NSString stringWithFormat:@"%d", count],
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

- (void)tmpHeartbeat
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

- (void)tmpUpdateStatus: (NSString *)status
{
    statusToPeer = status;
    NetworkOutputView *nov = NULL;
    if ([self.manager.outputView isKindOfClass:[NetworkOutputView class]]) {
        nov = (NetworkOutputView *)self.manager.outputView;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (nov) {
            nov.bNetworkStatus.stringValue = status;
        }
        if (self.selectionViewForStatusOnly) {
            self.selectionViewForStatusOnly.bNetworkStatus.stringValue = status;
        }
    });
}

- (void)tmpSetDeviceDescriptor: (DeviceDescription *)descr
{
    deviceDescriptorToSend = descr;
}
@end
