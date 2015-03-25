///
///  @file protocols.h
///  @brief Various protocols for which multiple implementations exist.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//


#ifndef videoLat_protocols_h
#define videoLat_protocols_h

#import "compat.h"

@class MeasurementDataStore;

/// Version of our document files (not program version).
#define VIDEOLAT_FILE_VERSION @"1.2"

/// Turn on global debugging, at compile time
#define VL_DEBUG 0

// Forward declarations
@protocol RunInputManagerProtocol;

@protocol MeasurementTypeProtocol
@property(readonly) NSUInteger tag;     //!< Tag for this type, used to order measurement types logically in menus.
@property(readonly) NSString *name;     //!< Human-readable type
@property(readonly) BOOL isCalibration; //!< True if this type is a calibration meaurement type
@property BOOL inputOnlyCalibration;    //!< True if only the input should match
@property BOOL outputOnlyCalibration;   //!< True if only the output should match
@property(readonly) NSObject<MeasurementTypeProtocol> *requires;  //!< What this measurement type depends on (usually a calibration) or nil.
@end


///
/// Protocol for an object that provides time values (in microseconds)
///
@protocol ClockProtocol
/**
 Get current time from this clock
 @return Timevalue in microseconds
 */
- (uint64_t)now;
@end

///
/// Protocol for an object that tracks a remote clock.
///
@protocol RemoteClockProtocol
///
/// Convert local time to remote time
///
- (uint64_t)remoteNow: (uint64_t) now;

///
/// Add measurement of round-trip
///
- (void)remote: (uint64_t)remote between: (uint64_t)start and: (uint64_t) finish;

///
/// Return round-trip-time
///
- (uint64_t)rtt;
@end

///
/// Protocol for an object that finds patterns in an image input buffer
///
@protocol InputVideoFindProtocol
@property(readonly) NSorUIRect rect;	/*!< Location of most recent pattern found */

/**
 Scan a grabbed image for a pattern this finder supports
 @param buffer the memory buffer containing the grabbed image
 @param width width in pixels
 @param height height in pixels
 @param format one of "RGB4", "Y800", "YUYV" or "UYUV"
 @param size size of buffer (in bytes)
 @return string representing the pattern, or nil
 */
- (char*) find: (void*)buffer width: (int)width height: (int)height format: (const char*)format size:(int)size;
@end

///
/// Protocol for an object that creates (visual) patterns in an image output buffer.
///
@protocol OutputVideoGenProtocol
/**
 Generate a detectable pattern
 @param buffer Where to store the image, as 8-bit greyscale
 @param width Width of the buffer in pixels
 @param height Height of the buffer in pixels
 @param code The string representation of the code to generate
 */
- (void) gen: (void*)buffer width: (int)width height: (int)height code: (const char *)code;
@end

///
/// Protocol for an object that is responsible for displaying patterns, and for
/// enabling the user to select the output device to use.
///
@protocol OutputViewProtocol
@property(readonly) NSString *deviceID;	//!< Unique string that identifies the output device
@property(readonly) NSString *deviceName;	//!< Human-readable string that identifies the output device
@property BOOL mirrored;	//!< Set to true to display the pattern mirrored

///
/// Makes output viewer request a new pattern from the OutputRunManager and display it.
///
- (void) showNewData;
@end

///
/// Protocol used by selectionView to communicate changes
///
@protocol SelectionViewDelegate
- (IBAction)selectionChanged: (id)sender;		//!< Called whenever input device or base measurement changes
- (IBAction)startPreMeasuring: (id)sender;		//!< Called when premeasuring button has been pressed
@end

///
/// Protocol for an object that allows selection of input device, base measurement (optional),
/// and starting of preruns and runs.
///
@protocol SelectionView
@property(weak) IBOutlet NSorUIButton *bPreRun;         //!< UI element: start preparing a measurement run
@property(weak) IBOutlet NSObject <SelectionViewDelegate> *selectionDelegate;

- (void)setBases: (NSArray *)baseNames;
- (void)disableBases;
- (NSString *)baseName;				//!< Returns name of selected base measurement
- (NSString *)deviceName;			//!< Returns name of selected input device
@end

@protocol NetworkViewProtocol
- (void) reportClient: (NSString *)ip port: (int)port isUs: (BOOL) us;
- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us;
@end

///
/// Protocol for an object that captures input patterns, and for enabling the user to
/// select the input device to use.
///
@protocol InputCaptureProtocol
@property (readonly) NSString* deviceID;	/*!< Unique string that identifies the input device */
@property (readonly) NSString* deviceName;	/*!< Human-readable string that identifies the input device */

/**
 Returns list of available input devices.
 */
- (NSArray*) deviceNames;
/*
 Switch to a different input device.
 @param Name of the device (as returned by deviceNames)
 @returns True if succesful
 */
- (BOOL)switchToDeviceWithName: (NSString *)name;
/**
 Start capturing, each captured frame will be forwarded to the InputRunManager.
 @param showPreview Set to true if the capturer should show its preview window
 */
- (void) startCapturing: (BOOL)showPreview;
/**
 Pause or resume capturer.
 @param pause True for pausing, false for resuming
 */
- (void) pauseCapturing: (BOOL)pause;
/**
 Pause capturing, don't forward frames to the InputRunManager any longer.
 */
- (void) stopCapturing;
/**
 Stop capturing altogether and release resources.
 */
- (void) stop;
@end

///
/// Protocol for a binary (monochrome) hardware input/output device.
///
@protocol HardwareLightProtocol
@property (readonly) NSString* deviceID;	/*!< Unique string that identifies the input device */
@property (readonly) NSString* deviceName;	/*!< Human-readable string that identifies the input device */
@property (readonly) NSString* lastErrorMessage;	/*!< Last error encountered, for example during initialization */

/**
 Test hardware device availability.
 @return True if the device exists and functions
 */
- (BOOL)available;
/**
 Measure light level.
 @return A value between 0.0 (dark) and 1.0 (light)
 */
- (double)light: (double)level;
@end

///
/// Protocol for an object that can provide data to a GraphView.
/// Think of this as an array of values with some statistics automatically applied.
///
@protocol GraphDataProviderProtocol
@property(readonly) int count;	/*!< Number of values available */
@property(readonly) double average;	/*!< Average of all values */
@property(readonly) double stddev;	/*!< Standard deviation of all values */
@property(readonly) double min;	/*!< Minimum value */
@property(readonly) double max;	/*!< Maximum value */
@property(readonly) double minXaxis;	/*!< For distribution plots: minimum bin value */
@property(readonly) double maxXaxis;	/*!< For distribution plots: maximum bin value */
@property(readonly) double binSize;	/*!< x-increments for which new values are available */

/**
 Return one value.
 @param i The index of the value to return
 @return The value
 */
- (NSNumber *)valueForIndex: (int) i;
@end

///
/// Protocol used by OutputViewProtocol objects to request new data and report results.
///
@protocol RunOutputManagerProtocol
///
/// Textual representation of the current output code, for example @"white", or
/// @"123456789" for QR code measurements. Set by the BaseRunManager that is
/// responsible for output, read by its inputCompanion.
///
@property(strong) NSString *outputCode;           // Current code on the display
//@property(weak) IBOutlet NSObject<RunInputManagerProtocol> *inputCompanion; //!< Our companion object that handles input
@property(weak) IBOutlet NSObject *inputCompanion; //!< Our companion object that handles input
@property(weak) IBOutlet NSorUIView <OutputViewProtocol> *outputView; //!< Assigned in NIB: Displays current output QR code

///
/// Called to prepare the output device, if needed, when restarting.
/// @return NO if not successful
- (BOOL) prepareOutputDevice;


- (BOOL)companionStartPreMeasuring;		//!< outputCompanion portion of startPreMeasuring
- (void)companionStopPreMeasuring;		//!< outputCompanion portion of stopPreMeasuring
- (void)companionStartMeasuring;		//!< outputCompanion portion of startMeasuring
- (void)companionStopMeasuring;			//!< outputCompanion portion of stopMeasuring
- (void)companionRestart;				//!< outputCompanion portion of restart
- (void)terminate;						//<! RunManager is about to disappear, clean up.

///
/// Prepare data for a new delay measurement. Called on the output companion, should
/// create a pattern that is distinghuisable from the previous pattern and display it.
///
- (void)triggerNewOutputValue;

///
/// Request a new output pattern.
/// @return The pattern to display, as a CIImage.
- (CIImage *)newOutputStart;
///
/// Signals that output pattern should now be visible. This records the timestamp.
///
- (void)newOutputDone;
@end

///
/// Protocol used by InputCaptureProtocol objects to report new data and timing.
///
@protocol RunInputManagerProtocol

@property(weak) IBOutlet NSObject<RunOutputManagerProtocol> *outputCompanion; //!< Our companion object that handles output

@property(readonly) NSObject<MeasurementTypeProtocol> *measurementType;
@property(readonly) int initialPrerunCount;
@property(readonly) int initialPrerunDelay;

///
/// Called from the SelectionView whenever the (input) device changes.
///
- (IBAction)selectionChanged: (id) sender;

///
/// Called to prepare the input device, if needed, when restarting.
/// @return NO if not successful
- (BOOL) prepareInputDevice;

///
/// Can be overridden by RunManagers responsible for input, to enforce certain codes to be
/// used during prerunning.
/// Implemented by the NetworkRunManager to communicate the ip/port of the listener to the remote
/// end.
///
- (NSString *)genPrerunCode;

///
/// Signals that a measurement run should be restarted (for example because the input device has changed).
///
- (void)restart;

- (void)terminate;  //<! RunManager is about to disappear, clean up.

- (IBAction)startPreMeasuring: (id)sender;  //!< Called when user presses "prepare" button
- (IBAction)stopPreMeasuring: (id)sender;   //!< Internal: stop pre-measuring because we have heard enough
- (IBAction)startMeasuring: (id)sender;     //!< Called when user presses "start" button

///
/// Not yet used.
///
- (void)setFinderRect: (NSorUIRect)theRect;

///
/// Signals that a capture cycle has started at the given time.
///
- (void)newInputStart:(uint64_t)timestamp;

///
/// Signals that a capture cycle has started now.
///
- (void)newInputStart;

///
/// Signals that a capture cycle has ended and provides the data.
/// @param data The data captured
/// @param count How often this exact data item has been detected already
/// @param timestamp The timestamp of the first capture of this data item
///
- (void) newInputDone: (NSString *)data count: (int)count at: (uint64_t) timestamp;

///
/// Signals that a capture cycle has ended and provides image data.
/// @param buffer The image data
/// @param w Width of the captured image in pixels
/// @param h Height of the captured image in pixels
/// @param formatStr One of "RGB4", "Y800", "YUYV" or "UYUV"
/// @param size Size of the buffer in bytes
///
- (void) newInputDone: (void*)buffer
    width: (int)w
    height: (int)h
    format: (const char*)formatStr
    size: (int)size;
///
/// Signals that a capture cycle has ended and provides audio data.
/// @param buffer The audio data, as 16 bit signed integer samples
/// @param size Size of the buffer in bytes
/// @param channels Number of channels (1 for mono, 2 for stereo)
/// @param timestamp Input capture time of this sample
///
- (void)newInputDone: (void*)buffer
    size: (int)size
    channels: (int)channels
    at: (uint64_t)timestamp;
///
/// Signals that a capture cycle has ended without providing any data.
///
- (void)newInputDone;
@end

///
/// Protocol that returns answers to "should I upload this calibration?" queries
///
@protocol UploadQueryDelegate
- (void) shouldUpload: (BOOL)answer;
@end

///
/// Protocol that returns answers to "Upload this calibration" commands
///
@protocol UploadDelegate
- (void) didUpload: (BOOL)answer;
@end

///
/// Protocol that returns answers to "Which calibrations are available for download?" queries
///
@protocol DownloadQueryDelegate
- (void) availableCalibrations: (NSArray *)allCalibrations;
@end

///
/// Protocol to open a new document, either after a download or because a measurement
/// has finished.
///
@protocol NewMeasurementDelegate
- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *)dataStore;
@end


#endif
