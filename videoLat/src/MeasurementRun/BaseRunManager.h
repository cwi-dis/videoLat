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
// Forward delcaration
@class NetworkIODevice;

///
/// Base class for objects that control a delay measurement run, i.e. a sequence of
/// many individual delay measurements and collects and stores the individual delays.
///
/// The class is also responsible for reporting measurements to a remote side (if this
/// is a two-ended measurement run).
///
/// In addition, the class methods implement a repository for remembering all available
/// measurement types and their NIBs (initialized by the class initializers of the subclasses).
///
@interface BaseRunManager : NSObject <RunManagerProtocol> {
    BOOL networkHelper;      //!< true if this is a networked helper, i.e. it has no collector.
    BOOL networkServer;       //!< true if this run manager is a network server (i.e. producing visual output to let the other side connect back here)

    uint64_t prepareMaxWaitTime;      //!< Internal: How long to wait for prerun code finding
    int prepareMoreNeeded;   //!< Internal: How many more prerun correct catches we need

    uint64_t averageFinderDuration; //!< Running average of how much the patternfinder takes

    uint64_t outputCodeTimestamp;   //!< When the last output code change was made

    NSString *prevInputCode;    //!< Last input code detected
    int prevInputCodeDetectionCount;    //!< How often prevInputCode was detected

    NSString *baseName;		//<! Name of our base (calibration) measurement
}

@property(weak) IBOutlet NSObject<InputSelectionView> *selectionView;         //!< Assigned in NIB: view that allows selection of input device
@property(weak) IBOutlet NSObject<InputDeviceProtocol> *capturer;    //!< Assigned in NIB: input capturer
@property(weak) IBOutlet NSorUIView <OutputDeviceProtocol> *outputView; //!< Assigned in NIB: Displays current output QR code
@property(weak) IBOutlet NSObject<NewMeasurementDelegate> *completionHandler;	//!< Optionally assigned in NIB: handler to open completed measurement
@property(weak) IBOutlet NetworkIODevice *networkIODevice;   //!< For hetwork measurements: the connection to the other side
@property(weak) IBOutlet NSObject<ClockProtocol> *clock; //!< Input manager clock

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

/// Textual representation of the current output code.
/// For example @"white", or
/// @"123456789" for QR code measurements.
@property(strong) NSString * outputCode;
/// Previous value of outputCode.
/// Used to forestall error messages in case we get a late detection of a previous code.
@property(strong) NSString * prevOutputCode;

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

@property bool running;		//!< True after user has pressed "run" button, false again after pressing "stop".
@property bool preparing;	//!< True after user has pressed "prepare" button, false again after pressing "run".

@property(weak) IBOutlet RunCollector *collector;			//!< Initialized in the NIB, RunCollector for this measurement run.
@property(weak) IBOutlet RunStatusView *statusView;			//!< Initialized in the NIB, RunStatusView for this measurement run.
#ifdef WITH_UIKIT
@property(weak) IBOutlet MeasurementContainerViewController *measurementMaster;	//!< Initialized in the NIB, our parent object.
#else
@property(weak) IBOutlet RunManagerView *measurementMaster;	//!< Initialized in the NIB, our parent object.
#endif

/// Update settings to measurement based on parameters (device name, etc) received from a remote
/// input or output handler.
- (BOOL)prepareMeasurementFromRemoteData;

/// Report input device name and other parameters to remote side.
- (BOOL)reportInputDeviceToRemote;

/// Report output device name and other parameters to remote side.
- (BOOL)reportOutputDeviceToRemote;

/// Report measurement results to remote input or output handler.
- (void)reportResultsToRemote: (MeasurementDataStore *)mr;


@end
