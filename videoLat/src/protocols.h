///
///  @file protocols.h
///  @brief Various protocols for which multiple implementations exist.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//


#ifndef videoLat_protocols_h
#define videoLat_protocols_h

#import "compat.h"

@class MeasurementDataStore;


/// Version of the program
#ifdef VIDEOLAT_VERSION
#define NSQUOTE(arg) @#arg
#define VIDEOLAT_VERSION_NSSTRING NSQUOTE(VIDEOLAT_VERSION)
#else
#define VIDEOLAT_VERSION_NSSTRING @"2.0"
#endif

/// Version of our document files (not program version).
#define VIDEOLAT_FILE_VERSION @"2.0"

/// Version of document files that we can still understand.
#define VIDEOLAT_COMPAT_FILE_VERSION @"1.2"

/// Turn on global debugging, at compile time
#define VL_DEBUG 0

#if !TARGET_OS_IPHONE
/// On OSX we enable detailed logging
#define WITH_LOGGING
#endif

/// We need a monotonic system clock. Define this to use the Mach clock service
#undef WITH_HOST_GET_CLOCK_SERVICE

/// Alternatively, we can use the Mach absolute time routines.
#define WITH_MACH_ABSOLUTE_TIME

/// We can also use per-device clocks, if available, which may be more precise.
#define WITH_DEVICE_CLOCK

/// If we don't use the device clock we can still resync our idea of the system clock
/// if it drifts too much. The value of the define is the allowable range (in microseconds)
/// before we start adjusting.
//#define WITH_ADJUST_CLOCK_DRIFT 30000
//#define WITH_ADJUST_CLOCK_DRIFT_FACTOR 2
//#undef WITH_ADJUST_CLOCK_DRIFT

/// If this is defined we throttle the video input capture rate.
/// This lowers the CPU load and makes measurements more predictable, at the expense of
/// having a (potentially much) larger inaccuracy.
#undef WITH_SET_MIN_CAPTURE_DURATION

///
/// Protocol implemented by MeasurementType, which describes details of what the measurement needs.
///
@protocol MeasurementTypeProtocol
@property(readonly) NSUInteger tag;     //!< Tag for this type, used to order measurement types logically in menus.
@property(readonly) NSString * _Nonnull name;     //!< Human-readable type
@property(readonly) BOOL isCalibration; //!< True if this type is a calibration meaurement type
@property BOOL inputOnlyCalibration;    //!< True if only the input should match
@property BOOL outputOnlyCalibration;   //!< True if only the output should match
@property(readonly) NSObject<MeasurementTypeProtocol> * _Nullable requires;  //!< What this measurement type depends on (usually a calibration) or nil.
@end


///
/// Protocol for an object that provides time values (in microseconds).
///
@protocol ClockProtocol

/// Get current time from this clock.
/// @return Timevalue in microseconds
- (uint64_t)now;
@end

///
/// Protocol for an object that finds patterns in an image input buffer.
///
@protocol InputVideoFindProtocol
@property(readonly) NSorUIRect rect;	//!< Location of most recent pattern found

/// Scan a grabbed image for a pattern this finder supports.
/// @param image the grabbed image
/// @return string representing the pattern, or nil
- (NSString *_Nullable) find: (CVImageBufferRef _Nonnull )image;

@optional
/// Optional method to set the area within the grabbed image that should be taken into account.
/// @param the area
- (void) setSensitiveArea: (NSorUIRect)rect;
@end

///
/// Protocol for an object that creates (visual) patterns in an image output buffer.
///
@protocol OutputVideoGenProtocol
/// Generate CIImage with a detectable pattern.
/// @param code NSString with the code to generate
/// @return the CIImage created
- (CIImage *_Nullable) genImageForCode: (NSString *_Nonnull)code size: (int)size;
@end

///
/// Protocol common to input and output devices.
///
@protocol CommonDeviceProtocol
@property(readonly) NSString * _Nonnull deviceID;    //!< Unique string that identifies the output device
@property(readonly) NSString * _Nonnull deviceName;    //!< Human-readable string that identifies the output device

/// Test hardware device availability.
/// @return True if the device exists and functions
- (BOOL)available;

/// Switch to a different input or output device, if possible.
/// @param Name of the device (as returned by deviceNames)
/// @return True if succesful
- (BOOL)switchToDeviceWithName: (NSString *_Nonnull)name;

/// Stop capturing or displaying altogether and release resources.
- (void) stop;
@end

///
/// Protocol for an object that is responsible for displaying patterns, and for
/// enabling the user to select the output device to use.
///
@protocol OutputDeviceProtocol <CommonDeviceProtocol>

/// Makes output viewer request a new pattern from the OutputRunManager and display it.
- (void) showNewData;
@end

///
/// Protocol for an object that captures input patterns.
///
@protocol InputDeviceProtocol <CommonDeviceProtocol>

/// List available input devices.
/// @return List of human-readable device names (as NSString)
- (NSArray* _Nonnull) deviceNames;

/// Start capturing, each captured frame will be forwarded to the InputRunManager
/// @param showPreview Set to true if the capturer should show its preview window (if applicable)
- (void) startCapturing: (BOOL)showPreview;

/// Pause or resume capturer, and release resources.
/// @param pause True for pausing, false for resuming
- (void) pauseCapturing: (BOOL)pause;

/// Stop forwarding frames to RunManager but continue running.
- (void) stopCapturing;

/// Set the minimum interval between capture callbacks, if supported.
/// @param interval Minimum time in microseconds between callbacks.
- (void)setMinCaptureInterval: (uint64_t)interval;
@end

///
/// Protocol used by selectionView to communicate changes
///
@protocol InputSelectionDelegate
#ifdef WITH_APPKIT
- (IBAction)inputSelectionChanged: (id _Nullable )sender;		//!< Called whenever input device or base measurement changes
#endif
@end

///
/// Protocol for an object that allows selection of input device, base measurement (optional),
/// and starting of preruns and runs.
///
@protocol InputSelectionView
/// Object to which this view should send changes in input device, base measurement and completion.
@property(weak) IBOutlet NSObject <InputSelectionDelegate> * _Nullable inputSelectionDelegate;

@property(readonly) NSString * _Nullable baseName;              //!< Returns name of currently selected base measurement
@property(readonly) NSString * _Nullable deviceName;            //!< Returns name of currently selected input device

#ifdef WITH_APPKIT
@property(weak) IBOutlet NSPopUpButton * _Nullable bBase;		//!< UI element: popup showing possible base measurements
@property(weak) IBOutlet NSPopUpButton * _Nullable bInputDevices;   //!< UI element: all available hardware

/// Called when the user makes a new selection in bInputDevices or bBase
- (IBAction)inputDeviceSelectionChanged: (id _Nullable ) sender;
#endif

/// Change the set of base measurements available in the UI.
/// @param baseNames Array of base names as NSString.
- (BOOL)setBases: (NSArray *_Nonnull)baseNames;

/// Disable (and possibly hide) the base measurement selector.
- (void)disableBases;


@end

///
/// Protocol for a view that shows the state of the network connection.
///
@protocol NetworkStatusProtocol

/// Report server identity.
/// @param ip Server IP address
/// @param port Server port
/// @param isUs True if we are the server
- (void) reportServer: (NSString *_Nonnull)ip port: (int)port isUs: (BOOL) us;

/// Report status.
- (void) reportStatus: (NSString *_Nonnull)status;

/// Report Roundtrip time.
- (void) reportRTT: (uint64_t)rtt best:(uint64_t)best;
@end

///
/// Protocol for a binary (monochrome) hardware input/output device.
///
@protocol HardwareLightProtocol <CommonDeviceProtocol>
@property (readonly) NSString* _Nullable lastErrorMessage;	//!< Last error encountered, for example during initialization

/// Test hardware device availability.
/// @return True if the device exists and functions
- (BOOL)available;

/// Combined light input/light output call.
/// @param level The output light level (between 0 and 1) to generate
/// @return The input light level measured
- (double)light: (double)level;
@end

///
/// Protocol for an object that can provide data to a GraphView.
/// Think of this as an array of values with some statistics automatically applied.
///
@protocol GraphDataProviderProtocol
@property(readonly) int count;	//!< Number of values available
@property(readonly) double average;	//!< Average of all values
@property(readonly) double stddev;	//!< Standard deviation of all values
@property(readonly) double min;	//!< Minimum value
@property(readonly) double max;	//!< Maximum value
@property(readonly) double minXaxis;	//!< For distribution plots: minimum bin value
@property(readonly) double maxXaxis;	//!< For distribution plots: maximum bin value
@property(readonly) double binSize;	//!< x-increments for which new values are available

/// Return one value.
/// @param i The index of the value to return
/// @return The value
- (NSNumber *_Nullable)valueForIndex: (int) i;
@end

///
/// Protocol used by InputDeviceProtocol objects to report new data and timing.
///
@protocol RunManagerProtocol <InputSelectionDelegate>


/// Request a new output pattern as an image.
/// @return The pattern to display, as a CIImage.
- (CIImage *_Nullable)getNewOutputImage;

/// Request string representation of new output code.
/// @return The string representing the output code.
- (NSString *_Nullable)getNewOutputCode;

/// Signals that output pattern is now visible.
/// This will record the output timestamp from the manager clock.
- (void)newOutputDone;

/// Signals that output pattern has been visible since the given timestamp.
- (void)newOutputDoneAt: (uint64_t)timestamp;

/// Signals that a measurement run should be restarted (for example because the input device has changed).
- (void)restart;

/// Change the active area for light detection in the input image.
- (void)setFinderRect: (NSorUIRect)theRect;

/// Signals that a capture cycle has ended and provides the data.
/// @param data The data captured
/// @param count How often this exact data item has been detected already
/// @param timestamp The timestamp of the first capture of this data item
- (void) newInputDone: (NSString *_Nonnull)data count: (int)count at: (uint64_t) timestamp;

/// Signals that a capture cycle has ended and provides image data.
/// @param image The image data
/// @param timestamp The timestamp of the image capture of this data item
- (void) newInputDone: (CVImageBufferRef _Nonnull )image at:(uint64_t)timestamp;

/// Signals that a capture cycle has ended and provides audio data.
/// @param buffer The audio data, as 16 bit signed integer samples
/// @param size Size of the buffer in bytes
/// @param channels Number of channels (1 for mono, 2 for stereo)
/// @param timestamp Timestamp in microseconds of the start of this sample
/// @param duration Duration of the sample in microseconds
///
- (void)newInputDone: (void*_Nonnull)buffer
    size: (int)size
    channels: (int)channels
    at: (uint64_t)timestamp
	duration: (uint64_t)duration;


#ifdef WITH_APPKIT
/// Show an error message sheet to the user
- (void)showErrorSheet: (NSString *_Nonnull)message;
/// Show an error message to the user, and run a completion code handler after the user presses the dismiss button.
- (void)showErrorSheet: (NSString *_Nonnull)message button:(NSString *_Nonnull)button handler:(void (^ __nullable)(void))handler;
#endif

@end

///
/// Protocol that returns answers to "should I upload this calibration?" queries
///
@protocol UploadQueryDelegate
- (void) calibrationIsFresh: (BOOL)answer;	//!< Signals whether the calibration should be uploaded
@end

///
/// Protocol that returns answers to "Upload this calibration" commands
///
@protocol UploadDelegate
- (void) didUpload: (BOOL)answer;	//!< Signals whether the upload was successful
@end

///
/// Protocol that returns answers to "Which calibrations are available for download?" queries
///
@protocol DownloadQueryDelegate
- (void) availableCalibrations: (NSArray *_Nonnull)allCalibrations;	//!< Reports list of all available calibrations
@end

///
/// Protocol to open a new document, either after a download or because a measurement
/// has finished.
///
@protocol NewMeasurementDelegate

/// Create a new document for a measurement.
/// @param dataStore The measurement data.
- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *_Nonnull)dataStore;
@end


#endif
