///
///  @file NetworkRunManager.h
///  @brief Defines NetworkRunManager object.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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
/// This class is never used as-is, it is always used as only an input component or only an output component.
///
@interface NetworkRunManager : BaseRunManager <NetworkProtocolDelegate> {
	uint64_t tsFrameEarliest;			//!< Earliest possible time the most recent frame may have been captured
	uint64_t tsFrameLatest;				//!< Latest possible time the most recent frame may have been captured

	uint64_t tsLastReported;			//!< Local timestamp of last qr-code detection reported to the master
	uint64_t tsLastReportedRemote;		//!< Remote timestamp of last qr-code detection reported to the master

    uint64_t lastMessageSentTime;       //!< Internal: Last time we sent a message to the master
    uint64_t lastDetectionReceivedTime; //!< Internal: Last time we received a QR-code detection
    NSString *prevInputCode;			//!< Internal: for checking monotonous increase
    NSString *prepareCode;               //!< Internal: data for prerun qrcode
    int prevInputCodeDetectionCount;    //!< Internal: Number of times we re-detected a code.
    uint64_t averageFinderDuration;		//!< Running average of how much the patternfinder takes
#ifdef WITH_SET_MIN_CAPTURE_DURATION
	BOOL captureDurationWasSet;
#endif
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
//@property(weak) IBOutlet NetworkOutputView *outputView;         //!< Assigned in NIB: visual feedback view of output for the user
@property(weak) IBOutlet NetworkSelectionView *selectionViewForStatusOnly;         //!< Assigned in NIB: view that allows viewing network status
@property NetworkProtocolCommon *protocol;

+ (void)initialize;	//!< Class initializer.

- (void)received: (NSDictionary *)data from: (id)connection;
- (void)disconnected:(id)me;

- (IBAction)startPreMeasuring: (id)sender;  //!< Called when user presses "prepare" button
- (IBAction)stopPreMeasuring: (id)sender;   //!< Internal: stop pre-measuring because we have heard enough
- (IBAction)startMeasuring: (id)sender;     //!< Called when user presses "start" button

- (NSString *)genPrepareCode;    //!< Returns QR-code containing our IP/port combination

@end
