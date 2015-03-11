///
///  @file NetworkRunManager.h
///  @brief Defines NetworkRunManager object.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "BaseRunManager.h"
#import "NetworkSelectionView.h"
#import "NetworkOutputView.h"
#import "NetworkProtocol.h"

///
/// Subclass of BaseRunManager that handles transmitting and receiving measurement
/// data over the network.
///
/// This calss is never used as-is, it is always used as only an input component or only an output component.
///
@interface NetworkRunManager : BaseRunManager <NetworkProtocolDelegate> {
    uint64_t inputStartTime;			//!< Internal: When last input was read, in local clock time
    uint64_t prevInputStartTime;		//!< Internal: When last input was read
	uint64_t prevInputStartTimeRemote;	//!< Internal: When last input was read, in remote clock time
    uint64_t lastMessageSentTime;       //!< Internal: Last time we sent a message to the master
    uint64_t lastDetectionReceivedTime; //!< Internal: Last time we received a QR-code detection
    NSString *prevInputCode;			//!< Internal: for checking monotonous increase
    NSString *prerunCode;               //!< Internal: data for prerun qrcode
    int prevInputCodeDetectionCount;    //!< Internal: Number of times we re-detected a code.
	NSObject <RemoteClockProtocol> *_keepRemoteClock;	//!< Internal: retain self-allocated clock
	DeviceDescription *remoteDevice;	//!< Internal: description of device used at the remote end
	DeviceDescription *deviceDescriptorToSend;	//!< Internal: description of local device, to be sent to remote
	NSString *statusToPeer;				//!< Internal: status update to be transmitted to peer
	BOOL didReceiveData;				//!< Internal: true once we have received any data
    BOOL sendMeasurementResults;        //!< Internal: send measurement results to remote
}

@property(weak) IBOutlet id <ClockProtocol> clock;              //!< Assigned in NIB: clock source
@property(weak) IBOutlet id <RemoteClockProtocol> remoteClock;	//!< Can be assigned in NIB: object keeping remote time.
@property(weak) IBOutlet NetworkSelectionView *selectionView;   //!< UI element: all available cameras
@property(weak) IBOutlet id <InputVideoFindProtocol> finder;    //!< Assigned in NIB: matches incoming QR codes
@property(weak) IBOutlet NetworkOutputView *outputView;         //!< Assigned in NIB: visual feedback view of output for the user
@property NetworkProtocolCommon *protocol;

+ (void)initialize;	//!< Class initializer.

// NetworkProtocolDelegate implementation
/// Received data from the remote end.
- (void)received: (NSDictionary *)data from: (id)connection;
/// Remote end disconnected or connection got lost some other way.
- (void)disconnected:(id)me;

- (IBAction)startPreMeasuring: (id)sender;  //!< Called when user presses "prepare" button
- (IBAction)stopPreMeasuring: (id)sender;   //!< Internal: stop pre-measuring because we have heard enough
- (IBAction)startMeasuring: (id)sender;     //!< Called when user presses "start" button

- (NSString *)genPrerunCode;    //!< Returns QR-code containing our IP/port combination

@end
