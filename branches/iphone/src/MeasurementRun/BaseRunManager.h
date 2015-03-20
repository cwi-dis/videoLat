///
///  @file BaseRunManager.h
///  @brief Defines BaseRunManager object.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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
/// If the object should handle both (for example during a VideoRun) both @see inputCompanion
/// and @see outputCompanion refer to self.
/// If the object should handle only input or output (for example during a MixedRun)
/// the @see inputCompanion of the output object refers to the other object
/// and vice versa.
///
/// In addition, the class methods implement a repository for remembering all available
/// measurement types and their NIBs (initialized by the class initializers of the subclasses).
///
@interface BaseRunManager : NSObject <RunOutputManagerProtocol, RunInputManagerProtocol> {
    BOOL handlesInput;		//!< true if we are responsible for input processing
    BOOL handlesOutput;		//!< true if we are responsible for output processing
    BOOL slaveHandler;      //!< true if this is a slave, i.e. it has no collector.
    uint64_t maxDelay;   //!< Internal: How log to wait for prerun code finding
    int prerunMoreNeeded;   //!< Internal: How many more prerun correct catches we need
}

@property(weak) IBOutlet id<SelectionView> selectionView;         //!< Assigned in NIB: view that allows selection of input device
@property(weak) IBOutlet NSObject<InputCaptureProtocol> *capturer;    //!< Assigned in NIB: input capturer
@property(weak) IBOutlet NSorUIView <OutputViewProtocol> *outputView; //!< Assigned in NIB: Displays current output QR code
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

@property(strong) MeasurementType *measurementType;
///
/// Textual representation of the current output code, for example @"white", or
/// @"123456789" for QR code measurements. Set by the BaseRunManager that is
/// responsible for output, read by its inputCompanion.
///
@property(strong) NSString *outputCode;           // Current code on the display

- (void)terminate;	//!< Prepare for deallocation. Severs links with companion and releases resources.
- (void)stop;	//!< Called when the user stops a measurement run, via @see stopMeasuring from @see RunTypeView
- (IBAction)stopMeasuring: (id)sender;	//!< Called when user presses "stop" button

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

///
/// Can be overridden by RunManagers responsible for input, to enforce certain codes to be
/// used during prerunning.
/// Implemented by the NetworkRunManager to communicate the ip/port of the listener to the remote
/// end.
///
- (NSString *)genPrerunCode;

@property bool running;		//!< True after user has pressed "run" button, false again after pressing "stop".
@property bool preRunning;	//!< True after user has pressed "prepare" button, false again after pressing "run".

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
