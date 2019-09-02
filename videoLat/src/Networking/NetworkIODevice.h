///
///  @file NetworkInput.h
///  @brief Implements getting measurement samples from another videoLat on the network.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//
#import "protocols.h"
#import "BaseRunManager.h"
#import "NetworkProtocol.h"
#import "RemoteClock.h"

///
/// Class that implements InputDeviceProtocol (and ClockProtocol) for data that
/// is actually captured remotely, and for which the data is sent to us over the network.
///
@interface NetworkIODevice : NSObject <ClockProtocol, InputDeviceProtocol, OutputDeviceProtocol, NetworkProtocolDelegate> {
    BOOL isServer;                //!< True if we are running in the network server (net input, screen output)
    BOOL isHelper;                //!< True if we are running on the helper side (initially the server)
    BOOL connected;               //!< True if we are connected
    NSString *prepareCode;        //!< Internal: data for prerun qrcode
    NSString *statusToPeer;       //!< Internal: status update to be transmitted to peer
    BOOL didReceiveData;          //!< Internal: true once we have received any data
    DeviceDescription *inputDeviceDescriptorToSend;    //!< Internal: description of local input device, to be sent to remote
    DeviceDescription *outputDeviceDescriptorToSend;    //!< Internal: description of local output device, to be sent to remote
    NSString *requestTransmissionCode;     //!< Internal: this side wants the other side to do a new transmission
    NSString *lastRequestTransmissionCode;  //!< Internal: last transmission requested
    RemoteClock *remoteClock;     //!< Internal: retain self-allocated clock
    uint64_t lastMessageSentTime; //!< Internal: Last time we sent a message to the master
}

@property(weak) IBOutlet BaseRunManager *manager;           //!< Our input manager
@property(weak) IBOutlet NSObject<ClockProtocol> *clock;    //!< Our clock, if not ourselves
@property(weak) IBOutlet NSObject<NetworkStatusProtocol> *networkStatusView;         //!< Assigned in NIB: view that allows viewing network status
//@property(weak) IBOutlet id selectionViewForStatusOnly;         //!< Assigned in NIB: view that allows viewing network status

@property(strong) NetworkProtocolCommon *protocol;
@property(strong) DeviceDescription *remoteInputDeviceDescription;
@property(strong) DeviceDescription *remoteOutputDeviceDescription;

- (uint64_t)now;
- (void) startCapturing: (BOOL) showPreview;
- (void) stopCapturing;
- (void) stop;
- (NSString *)genPrepareCode;    //!< Returns QR-code containing our IP/port combination

// xxxjack temp
- (void)openServer: (BOOL)asHelper;
- (void)openClient: (BOOL)asHelper url: (NSString *)url;
- (void)reportResult: (MeasurementDataStore *)ds;
- (void)reportReception: (NSString *)code count:(int)count at:(uint64_t)timestamp;
- (void)reportTransmission: (NSString *)code at:(uint64_t)timestamp;
- (void)reportHeartbeat;
- (void)reportStatus: (NSString *)status;
- (void)reportInputDevice: (DeviceDescription *)descr;
- (void)reportOutputDevice: (DeviceDescription *)descr;
@end
