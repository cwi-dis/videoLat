///
///  @file NetworkInput.h
///  @brief Implements getting measurement samples from another videoLat on the network.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//
#import "protocols.h"
#import "BaseRunManager.h"
#import "NetworkSelectionView.h"
#import "NetworkProtocol.h"
#import "RemoteClock.h"

///
/// Class that implements InputDeviceProtocol (and ClockProtocol) for data that
/// is actually captured remotely, and for which the data is sent to us over the network.
///
@interface NetworkInput : NSObject <ClockProtocol, InputDeviceProtocol, NetworkProtocolDelegate> {
    BOOL isClient;                //!< True if we are running in the network client (camera input, outputnet)
    BOOL isServer;                //!< True if we are running in the network server (net input, screen output)
    NSString *prepareCode;        //!< Internal: data for prerun qrcode
    NSString *statusToPeer;       //!< Internal: status update to be transmitted to peer
    BOOL didReceiveData;          //!< Internal: true once we have received any data
    DeviceDescription *deviceDescriptorToSend;    //!< Internal: description of local device, to be sent to remote
    RemoteClock *remoteClock;     //!< Internal: retain self-allocated clock
    uint64_t lastMessageSentTime; //!< Internal: Last time we sent a message to the master
}

@property(weak) IBOutlet BaseRunManager *manager;           //!< Our input manager
@property(weak) IBOutlet BaseRunManager *outputManager;     //!< Our output manager, if different
@property(weak) IBOutlet NSObject<ClockProtocol> *clock;    //!< Our clock, if not ourselves
@property(weak) IBOutlet NSObject<NetworkStatusProtocol> *networkStatusView;         //!< Assigned in NIB: view that allows viewing network status
//@property(weak) IBOutlet id selectionViewForStatusOnly;         //!< Assigned in NIB: view that allows viewing network status

@property(strong) NetworkProtocolCommon *protocol;
@property(strong) DeviceDescription *remoteDeviceDescription;

- (uint64_t)now;
- (void) startCapturing: (BOOL) showPreview;
- (void) stopCapturing;
- (void) stop;
- (NSString *)genPrepareCode;    //!< Returns QR-code containing our IP/port combination

// xxxjack temp
- (void)tmpOpenServer;
- (void)tmpOpenClient: (NSString *)url;
- (void)tmpSendResult: (MeasurementDataStore *)ds;
- (void)tmpReport: (NSString *)code count:(int)count at:(uint64_t)tsLastReported;
- (void)tmpHeartbeat;
- (void)tmpUpdateStatus: (NSString *)status;
- (void)tmpSetDeviceDescriptor: (DeviceDescription *)descr;
@end
