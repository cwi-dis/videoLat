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
    NSString *prevInputCode;			//!< Internal: for checking monotonous increase
    NSString *prerunCode;               //!< Internal: data for prerun qrcode
    int prevInputCodeDetectionCount;    //!< Internal: Number of times we re-detected a code.
	NSObject <RemoteClockProtocol> *_keepRemoteClock;	//!< Internal: retain self-allocated clock
}

@property(weak) IBOutlet id <ClockProtocol> clock;              //!< Assigned in NIB: clock source
@property(weak) IBOutlet id <RemoteClockProtocol> remoteClock;	//!< Can be assigned in NIB: object keeping remote time.
@property(weak) IBOutlet NetworkSelectionView *selectionView;   //!< UI element: all available cameras
@property(weak) IBOutlet id <InputCaptureProtocol> capturer;    //!< Assigned in NIB: video capturer
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
#if 0
///
/// Register a BaseRunManager subclass for a specific measurement type.
/// @param managerClass the class object that implements the measurement type
/// @param name the (human readable) name of this measurement type
///
+ (void)registerClass: (Class)managerClass forMeasurementType: (NSString *)name;

///
/// Return the class implementing a measurement type.
/// @param name the name of the measurement type
/// @return the class object implementing the measurement type
///
+ (Class)classForMeasurementType: (NSString *)name;

///
/// Register a NIB file that implements a specific measurement type.
/// @param nibName the name of the nibfile
/// @param name the (human readable) name of the measurement type
///
+ (void)registerNib: (NSString*)nibName forMeasurementType: (NSString *)name;

///
/// Return the NIB filename implementing a measurement type.
/// @param name the name of the measurement type
/// @return the NIB name implementing the measurement type
///
+ (NSString *)nibForMeasurementType: (NSString *)name;

@property(readonly) MeasurementType *measurementType;
///
/// Textual representation of the current output code, for example @"white", or
/// @"123456789" for QR code measurements. Set by the BaseRunManager that is
/// responsible for output, read by its inputCompanion.
///
@property(strong) NSString *outputCode;           // Current code on the display

- (void)terminate;	//!< Prepare for deallocation. Severs links with companion and releases resources.
- (void)stop;	//!< Called when the user stops a measurement run, via @see stopMeasuring from @see RunTypeView

///
/// Select the actual measurement type this run will use.
/// @param typeName the (human readable) measurement type name.
/// This method is needed because many measurement types (for example Video Roundtrip and Video Calibration)
/// share an awful lot of code.
///
- (void)selectMeasurementType: (NSString *)typeName;
- (void)restart;

///
/// Prepare data for a new delay measurement. Called on the output companion, should
/// create a pattern that is distinghuisable from the previous pattern and display it.
///
- (void)triggerNewOutputValue;

@property bool running;		//!< True after user has pressed "run" button, false again after pressing "stop".
@property bool preRunning;	//!< True after user has pressed "prepare" button, false again after pressing "run".

@property(weak) IBOutlet RunCollector *collector;			//!< Initialized in the NIB, RunCollector for this measurement run.
@property(weak) IBOutlet RunStatusView *statusView;			//!< Initialized in the NIB, RunStatusView for this measurement run.
@property(weak) IBOutlet RunTypeView *measurementMaster;	//!< Initialized in the NIB, our parent object.

//@{
/// The inputCompanion and outputCompanion properties need a bit of explanation.
/// If the same RunManager is used for
/// both input and output the following two outlets are NOT assigned in the NIB.
/// The will then be both set to self in awakeFromNib, and this run manager handles both
/// input and output.
/// But for non-symetric measurements (say, hardware light to camera) the NIB instantiates
/// two BaseRunManager subclass instances, and ties them together through the inputCompanion
/// and outputCompanion.
///
@property(weak) IBOutlet BaseRunManager *inputCompanion; //!< Our companion object that handles input

@property(weak) IBOutlet BaseRunManager *outputCompanion; //!< Our companion object that handles output
//@}

#endif
@end
