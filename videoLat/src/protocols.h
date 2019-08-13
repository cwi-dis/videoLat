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

// Forward declarations
@protocol RunInputManagerProtocol;

///
/// Protocol implemented by MeasurementType, which describes details of what the measurement needs.
///
@protocol MeasurementTypeProtocol
@property(readonly) NSUInteger tag;     //!< Tag for this type, used to order measurement types logically in menus.
@property(readonly) NSString *name;     //!< Human-readable type
@property(readonly) BOOL isCalibration; //!< True if this type is a calibration meaurement type
@property BOOL inputOnlyCalibration;    //!< True if only the input should match
@property BOOL outputOnlyCalibration;   //!< True if only the output should match
@property(readonly) NSObject<MeasurementTypeProtocol> *requires;  //!< What this measurement type depends on (usually a calibration) or nil.
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
/// Protocol for an object that tracks a remote clock.
///
@protocol RemoteClockProtocol

/// Convert local time to remote time.
/// @param now Local time in microseconds
/// @return Remote time in microseconds
- (uint64_t)remoteNow: (uint64_t) now;

/// Add measurement of round-trip delay to update local-to-remote time mapping.
/// @param remote Remote clock time reported in the reply packet
/// @param start Local clock time we sent the request packet
/// @param finish Local clock time we received the reply packet
///
- (void)remote: (uint64_t)remote between: (uint64_t)start and: (uint64_t) finish;

/// Return round-trip-time.
/// @return Current round trip time
- (uint64_t)rtt;

/// Return rtt used to determine current clock synchronization.
/// @return Best rtt measured
- (uint64_t)clockInterval;
@end

///
/// Protocol for an object that finds patterns in an image input buffer.
///
@protocol InputVideoFindProtocol
@property(readonly) NSorUIRect rect;	//!< Location of most recent pattern found

/// Scan a grabbed image for a pattern this finder supports.
/// @param image the grabbed image
/// @return string representing the pattern, or nil
- (NSString *) find: (CVImageBufferRef)image;

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
- (CIImage *) genImageForCode: (NSString *)code size: (int)size;
@end

///
/// Protocol to determine device names
///
@protocol DeviceNameProtocol
@property(readonly) NSString *deviceID;    //!< Unique string that identifies the output device
@property(readonly) NSString *deviceName;    //!< Human-readable string that identifies the output device
@end

///
/// Protocol for an object that is responsible for displaying patterns, and for
/// enabling the user to select the output device to use.
///
@protocol OutputDeviceProtocol <DeviceNameProtocol>

/// Makes output viewer request a new pattern from the OutputRunManager and display it.
- (void) showNewData;
@end

///
/// Protocol used by selectionView to communicate changes
///
@protocol InputSelectionDelegate
- (IBAction)inputSelectionChanged: (id)sender;		//!< Called whenever input device or base measurement changes
- (IBAction)startPreMeasuring: (id)sender;		//!< Called when premeasuring button has been pressed
@end

///
/// Protocol for an object that allows selection of input device, base measurement (optional),
/// and starting of preruns and runs.
///
@protocol InputSelectionView
/// Object to which this view should send changes in input device, base measurement and completion.
@property(weak) IBOutlet NSObject <InputSelectionDelegate> *inputSelectionDelegate;

@property(readonly) NSString *baseName;              //!< Returns name of currently selected base measurement
@property(readonly) NSString *deviceName;            //!< Returns name of currently selected input device

#ifdef WITH_APPKIT
@property(weak)IBOutlet NSPopUpButton *bBase;		//!< UI element: popup showing possible base measurements
@property(weak) IBOutlet NSPopUpButton *bInputDevices;   //!< UI element: all available hardware
@property(weak) IBOutlet NSButton *bPreRun;         //!< UI element: start preparing a measurement run

/// Called when the user makes a new selection in bDevices
- (IBAction)inputDeviceChanged: (id) sender;
#endif

#ifdef WITH_UIKIT
/// Change the set of base measurements available in the UI.
/// @param baseNames Array of base names as NSString.
- (void)setBases: (NSArray *)baseNames;

/// Disable (and possibly hide) the base measurement selector.
- (void)disableBases;
#endif


@end

///
/// Protocol for a view that shows the state of the network connection.
///
@protocol NetworkViewProtocol

/// Set client identity.
/// @param ip Client IP address
/// @param port Client port
/// @param isUs True if we are the client
- (void) reportClient: (NSString *)ip port: (int)port isUs: (BOOL) us;

/// Set server identity.
/// @param ip Server IP address
/// @param port Server port
/// @param isUs True if we are the server
- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us;
@end

///
/// Protocol for an object that captures input patterns.
///
@protocol InputDeviceProtocol <DeviceNameProtocol>

/// List available input devices.
/// @return List of human-readable device names (as NSString)
- (NSArray*) deviceNames;

/// Switch to a different input device.
/// @param Name of the device (as returned by deviceNames)
/// @return True if succesful
- (BOOL)switchToDeviceWithName: (NSString *)name;

/// Start capturing, each captured frame will be forwarded to the InputRunManager
/// @param showPreview Set to true if the capturer should show its preview window (if applicable)
- (void) startCapturing: (BOOL)showPreview;

/// Pause or resume capturer, and release resources.
/// @param pause True for pausing, false for resuming
- (void) pauseCapturing: (BOOL)pause;

/// Stop forwarding frames to RunManager but continue running.
- (void) stopCapturing;

/// Stop capturing altogether and release resources.
- (void) stop;

/// Set the minimum interval between capture callbacks, if supported.
/// @param interval Minimum time in microseconds between callbacks.
- (void)setMinCaptureInterval: (uint64_t)interval;
@end

///
/// Protocol for a binary (monochrome) hardware input/output device.
///
@protocol HardwareLightProtocol <DeviceNameProtocol>
@property (readonly) NSString* lastErrorMessage;	//!< Last error encountered, for example during initialization

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
- (NSNumber *)valueForIndex: (int) i;
@end

///
/// Protocol used by OutputDeviceProtocol objects to request new data and report results.
///
@protocol RunOutputManagerProtocol

/// Textual representation of the current output code.
/// For example @"white", or
/// @"123456789" for QR code measurements. Set by the BaseRunManager that is
/// responsible for output, read by its inputCompanion.
///
@property(strong) NSString *outputCode;
/// Previous value of outputCode.
/// Used to forestall error messages in case we get a late detection of a previous code.
@property(strong) NSString *prevOutputCode;


@property(weak) IBOutlet NSObject *inputCompanion; //!< Our companion object that handles input
@property(weak) IBOutlet NSorUIView <OutputDeviceProtocol> *outputView; //!< Assigned in NIB: Displays current output QR code

/// Called to prepare the output device, if needed, when restarting.
/// @return NO if not successful
- (BOOL) prepareOutputDevice;


- (BOOL)companionStartPreMeasuring;		//!< outputCompanion portion of startPreMeasuring
- (void)companionStopPreMeasuring;		//!< outputCompanion portion of stopPreMeasuring
- (void)companionStartMeasuring;		//!< outputCompanion portion of startMeasuring
- (void)companionStopMeasuring;			//!< outputCompanion portion of stopMeasuring
- (void)companionRestart;				//!< outputCompanion portion of restart
- (void)terminate;						//<! RunManager is about to disappear, clean up.


/// Prepare data for a new delay measurement.
/// Called on the output companion, should
/// create a pattern that is distinghuisable from the previous pattern and display it.
///
- (void)triggerNewOutputValue;

/// Prepare data for a new delay measurement, possibly after a delay to forestall lock-step behaviour.
/// Called on the output companion, will call triggerNewOutputValue after a delay.
- (void)triggerNewOutputValueAfterDelay;

/// Request a new output pattern.
/// @return The pattern to display, as a CIImage.
- (CIImage *)newOutputStart;

/// Signals that output pattern is now visible.
/// This will record the output timestamp.
- (void)newOutputDone;
@end

///
/// Protocol used by InputDeviceProtocol objects to report new data and timing.
///
@protocol RunInputManagerProtocol <InputSelectionDelegate>

@property(weak) IBOutlet NSObject<RunOutputManagerProtocol> *outputCompanion; //!< Our companion object that handles output
@property(weak) NSObject<ClockProtocol> *clock; //!< Input manager clock
@property(readonly) NSObject<MeasurementTypeProtocol> *measurementType;	//!< The type of measurement we are doing
@property(readonly) int initialPrerunCount;	//!< How many detections are needed during prerun
@property(readonly) int initialPrerunDelay;	//!< The current (or final) delay between prerun generations.

/// Called to prepare the input device, if needed, when restarting.
/// @return NO if not successful
- (BOOL) prepareInputDevice;

/// Can be overridden by RunManagers responsible for input, to enforce certain codes to be
/// used during prerunning.
/// Implemented by the NetworkRunManager to communicate the ip/port of the listener to the remote
/// end.
/// @return the prerun code to use.
- (NSString *)genPrerunCode;

/// Signals that a measurement run should be restarted (for example because the input device has changed).
- (void)restart;

/// RunManager is about to disappear, clean up.
- (void)terminate;

/// Stop pre-measuring because we have enough prerun samples.
- (IBAction)stopPreMeasuring: (id)sender;

/// Called when user presses "start" button.
- (IBAction)startMeasuring: (id)sender;

/// Unused.
- (void)setFinderRect: (NSorUIRect)theRect;

/// Signals that a capture cycle has started at the given time.
/// @param timestamp When the cycle started, in microseconds.
- (void)newInputStart:(uint64_t)timestamp;

/// Signals that a capture cycle has ended and provides the data.
/// @param data The data captured
/// @param count How often this exact data item has been detected already
/// @param timestamp The timestamp of the first capture of this data item
- (void) newInputDone: (NSString *)data count: (int)count at: (uint64_t) timestamp;

/// Signals that a capture cycle has ended and provides image data.
/// @param image The image data
- (void) newInputDone: (CVImageBufferRef)image;

/// Signals that a capture cycle has ended and provides audio data.
/// @param buffer The audio data, as 16 bit signed integer samples
/// @param size Size of the buffer in bytes
/// @param channels Number of channels (1 for mono, 2 for stereo)
/// @param timestamp Timestamp in microseconds of the start of this sample
/// @param duration Duration of the sample in microseconds
///
- (void)newInputDone: (void*)buffer
    size: (int)size
    channels: (int)channels
    at: (uint64_t)timestamp
	duration: (uint64_t)duration;
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
- (void) availableCalibrations: (NSArray *)allCalibrations;	//!< Reports list of all available calibrations
@end

///
/// Protocol to open a new document, either after a download or because a measurement
/// has finished.
///
@protocol NewMeasurementDelegate

/// Create a new document for a measurement.
/// @param dataStore The measurement data.
- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *)dataStore;
@end


#endif
