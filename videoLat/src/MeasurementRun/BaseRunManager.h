///
///  @file BaseRunManager.h
///  @brief Defines BaseRunManager object.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "protocols.h"
#import "MeasurementType.h"
#import "RunCollector.h"
#import "RunManagerView.h"
#import "RunStatusView.h"
#ifdef WITH_UIKIT
#import "MeasurementContainerViewController.h"
#endif
#ifdef WITH_APPKIT
#import "RunManagerView.h"
#endif

///
/// Base class for objects that control a delay measurement run, i.e. a sequence of
/// many individual delay measurements and collects and stores the individual delays.
///
/// Implementations of this class should be able to handle both input and output, but
/// they may have to handle only one of those, based on how things are initialized in the NIB.
/// If the object should handle both (for example during a VideoRun) both inputCompanion
/// and outputCompanion refer to self.
/// If the object should handle only input or output (for example during a MixedRun)
/// the inputCompanion of the output object refers to the other object
/// and vice versa.
///
/// In addition, the class methods implement a repository for remembering all available
/// measurement types and their NIBs (initialized by the class initializers of the subclasses).
///
@interface BaseRunManager : NSObject <RunOutputManagerProtocol, RunInputManagerProtocol> {
    BOOL handlesInput;		//!< true if we are responsible for input processing
    BOOL handlesOutput;		//!< true if we are responsible for output processing
    BOOL slaveHandler;      //!< true if this is a slave, i.e. it has no collector.

    uint64_t prepareMaxWaitTime;      //!< Internal: How long to wait for prerun code finding
    int prepareMoreNeeded;   //!< Internal: How many more prerun correct catches we need

    uint64_t averageFinderDuration; //!< Running average of how much the patternfinder takes

    uint64_t outputCodeTimestamp;   //!< When the last output code change was made

    NSString *baseName;		//<! Name of our base (calibration) measurement
}

@property(weak) IBOutlet NSObject<InputSelectionView> *selectionView;         //!< Assigned in NIB: view that allows selection of input device
@property(weak) IBOutlet NSObject<InputDeviceProtocol> *capturer;    //!< Assigned in NIB: input capturer
@property(weak) IBOutlet NSorUIView <OutputDeviceProtocol> *outputView; //!< Assigned in NIB: Displays current output QR code
@property(weak) IBOutlet NSObject<NewMeasurementDelegate> *completionHandler;	//!< Optionally assigned in NIB: handler to open completed measurement
+ (void)initialize;	//!< Class initializer.

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

#ifdef WITH_UIKIT
///
/// Register a NIB file that implements selecting the inputs for a specific measurement type.
/// @param nibName the name of the nibfile
/// @param name the (human readable) name of the measurement type
///
+ (void)registerSelectionNib: (NSString*)nibName forMeasurementType: (NSString *)name;

///
/// Return the NIB filename implementing a measurement type.
/// @param name the name of the measurement type
/// @return the NIB name implementing the measurement type
///
+ (NSString *)selectionNibForMeasurementType: (NSString *)name;

#endif

@property(strong) MeasurementType *measurementType;

/// Textual representation of the current output code, for example @"white", or
/// @"123456789" for QR code measurements. Set by the BaseRunManager that is
/// responsible for output, read by its inputCompanion.
@property(strong) NSString *outputCode;           // Current code on the display

- (void)terminate;	//!< Prepare for deallocation. Severs links with companion and releases resources.
- (void)stop;	//!< Called when the user stops a measurement run, via stopMeasuring from RunTypeView

- (IBAction)startPreMeasuring: (id)sender;  //!< Called when premeasuring button has been pressed
- (void)stopPreMeasuring: (id)sender; 	    //!< Stop pre-measuring because we have enough prerun samples.
- (IBAction)startMeasuring: (id)sender;	    //!< Called when user presses "start" button.
- (IBAction)stopMeasuring: (id)sender;	    //!< Called when user presses "stop" button

/// Select the actual measurement type this run will use.
/// @param typeName the (human readable) measurement type name.
/// This method is needed because many measurement types (for example QR Code Roundtrip and Video Calibration)
/// share an awful lot of code.
- (void)selectMeasurementType: (NSString *)typeName;

#ifdef WITH_UIKIT

/// Select the measurement type and base, and start prerunning.
/// @param measurementTypeName The type of measurement
/// @param baseMeasurementName The name of the base measurement (or nil)
- (void)runForType: (NSString *)measurementTypeName withBase: (NSString *)baseMeasurementName;
#endif

/// Signals that a measurement run should be restarted (for example because the input device has changed).
- (void)restart;

/// Prepare data for a new delay measurement.
/// Called on the output companion, should
/// create a pattern that is distinghuisable from the previous pattern and display it.
- (void)triggerNewOutputValue;

/// Prepare data for a new delay measurement, possibly after a delay to forestall lock-step behaviour.
/// Called on the output companion, will call triggerNewOutputValue after a delay.
- (void)triggerNewOutputValueAfterDelay;

- (void) prepareReceivedNoValidCode;                  //!< Internal: no QR code was received in time during prerun
- (void) prepareReceivedValidCode: (NSString *)code;  //!< Internal: QR code was received in time during prerun

/// Can be overridden by RunManagers responsible for input, to enforce certain codes to be
/// used during prerunning.
/// Implemented by the NetworkRunManager to communicate the ip/port of the listener to the remote
/// end.
/// @return the prerun code to use.
- (NSString *)genPrepareCode;

@property bool running;		//!< True after user has pressed "run" button, false again after pressing "stop".
@property bool preparing;	//!< True after user has pressed "prepare" button, false again after pressing "run".

@property(weak) IBOutlet RunCollector *collector;			//!< Initialized in the NIB, RunCollector for this measurement run.
@property(weak) IBOutlet RunStatusView *statusView;			//!< Initialized in the NIB, RunStatusView for this measurement run.
#ifdef WITH_UIKIT
@property(weak) IBOutlet MeasurementContainerViewController *measurementMaster;	//!< Initialized in the NIB, our parent object.
#else
@property(weak) IBOutlet RunManagerView *measurementMaster;	//!< Initialized in the NIB, our parent object.
#endif

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
@property(weak) IBOutlet NSObject<RunInputManagerProtocol> *inputCompanion; //!< Our companion object that handles input

@property(weak) IBOutlet NSObject<RunOutputManagerProtocol> *outputCompanion; //!< Our companion object that handles output
//@}

@end
