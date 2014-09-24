//
//  protocols.h
//  videoLat
//
//  Created by Jack Jansen on 06/11/13.
//
//

#ifndef videoLat_protocols_h
#define videoLat_protocols_h
#import <Cocoa/Cocoa.h>

// This constant needs to go somewhere...
#define VIDEOLAT_FILE_VERSION @"0.5"

// Global debug stuff
#define VL_DEBUG 0

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
/// Protocol for an object that finds patterns in an image input buffer
///
@protocol InputVideoFindProtocol
@property(readonly) NSRect rect;	/*!< Location of most recent pattern found */

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
/// Protocol for an object that captures input patterns, and for enabling the user to
/// select the input device to use.
///
@protocol InputCaptureProtocol
@property (readonly) NSString* deviceID;	/*!< Unique string that identifies the input device */
@property (readonly) NSString* deviceName;	/*!< Human-readable string that identifies the input device */
/**
 Start capturing, each captured frame will be forwarded to the InputRunManager.
 @param showPreview Set to true if the capturer should show its preview window
 */
- (void) startCapturing: (BOOL)showPreview;
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
@property(readonly) double maxXaxis;	/*!< For distribution plots: maximum bin value */

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
/**
 Request a new output pattern.
 @return The pattern to display, as a CIImage.
 */
- (CIImage *)newOutputStart;
/**
 Signals that output pattern should now be visible. This records the timestamp.
 */
- (void)newOutputDone;
@end

///
/// Protocol used by InputCaptureProtocol objects to report new data and timing.
///
@protocol RunInputManagerProtocol
/**
 Signals that a measurement run should be restarted (for example because the input device has changed).
 */
- (void)restart;
/**
 Not yet used.
 */
- (void)setFinderRect: (NSRect)theRect;
/**
 Signals that a capture cycle has started at the given time.
 */
- (void)newInputStart:(uint64_t)timestamp;
/**
 Signals that a capture cycle has started now.
 */
- (void)newInputStart;
/**
 Signals that a capture cycle has ended and provides image data.
 @param buffer The image data
 @param w Width of the captured image in pixels
 @param h Height of the captured image in pixels
 @param formatStr One of "RGB4", "Y800", "YUYV" or "UYUV"
 @param size Size of the buffer in bytes
 */
- (void) newInputDone: (void*)buffer
    width: (int)w
    height: (int)h
    format: (const char*)formatStr
    size: (int)size;
/**
 Signals that a capture cycle has ended and provides audio data.
 @param buffer The audio data, as 16 bit signed integer samples
 @param size Size of the buffer in bytes
 @param channels Number of channels (1 for mono, 2 for stereo)
 @param timestamp Input capture time of this sample
 */
- (void)newInputDone: (void*)buffer
    size: (int)size
    channels: (int)channels
    at: (uint64_t)timestamp;
/**
 Signals that a capture cycle has ended without providing any data.
 */
- (void)newInputDone;
@end
#endif
