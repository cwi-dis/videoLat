///
///  @file VideoInput.h
///  @brief Video camera driver using AVFoundation.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//
#import <AVFoundation/AVFoundation.h>
#import "protocols.h"
#import "GenQRcode.h"
#define WITH_STATISTICS

///
/// Subclass of NSView that shows preview of what the camera has captured, helper class
/// for VideoInput class.
///
@interface VideoInputView
#ifdef WITH_UIKIT
: UIView
#else
: NSView
#endif
{
#ifdef WITH_APPKIT
	NSPoint downPoint;      //!< Internal: position of mouse down event
#endif
}
@property (weak) IBOutlet id delegate;  //!< Set by NIB: corresponding VideoInput object
@property (weak) IBOutlet NSorUIButton *visibleButton;  //!< UI element, allows user to toggle video preview

#ifdef WITH_APPKIT
- (IBAction)visibleChanged:(id)sender;  //!< Called when user toggles visibleButton
- (void)mouseDown: (NSEvent *)theEvent; //!< Mouse event handler, to allow selecting a rectangular area
- (void)mouseUp: (NSEvent *)theEvent;   //!< Mouse event handler, to allow selecting a rectangular area
#endif

@end

///
/// Class that implements InputDeviceProtocol (and ClockProtocol) for video input, using
/// AVCapture to capture a video stream from a camera.
///
@interface VideoInput : NSObject <ClockProtocol, InputDeviceProtocol, AVCaptureVideoDataOutputSampleBufferDelegate, CALayerDelegate> {
    CALayer *selfLayer;		                    //!< Our self-view in the UI
    CALayer *overlayLayer;                      //!< Overlay layer for rectangles and such
    AVCaptureVideoDataOutput *outputCapturer;	//!< Object that forwards frames to use
	AVCaptureSession *session;					//!< Currently running capture session
    dispatch_queue_t sampleBufferQueue;			//!< Used by outputCapturer to communicate with us
	float xFactor, yFactor;
#ifdef WITH_DEVICE_CLOCK
    CMClockRef clock;							//!< Clock of the current video input device.
#endif
    uint64_t epoch;								//!< Time zero of clock
	BOOL capturing;
#ifdef WITH_STATISTICS
	// Statistics
	uint64_t firstTimeStamp;					//!< First frame timestamp
	uint64_t lastTimeStamp;						//!< Latest frame timestamp
	int nFrames;								//!< Number of frames received
	int nFramesDropped;
#endif
}
@property(weak) IBOutlet id <RunManagerProtocol> manager;
@property(weak) IBOutlet VideoInputView *selfView;	//!< View showing what our camera sees
@property NSArray* overlayRects;

+ (NSArray *) allDeviceTypeIDs;	//!< Returns a list of all known video devices.
+ (NSArray*) deviceNames;
- (uint64_t)now;

- (bool)available;
- (NSArray*) deviceNames;
- (BOOL)switchToDeviceWithName: (NSString *)name;
- (void) startCapturing: (BOOL) showPreview;
- (void) pauseCapturing: (BOOL) pause;
- (void) stopCapturing;

- (void) stop;

- (AVCaptureDevice*)_deviceWithName: (NSString*)name;
- (void)_switchToDevice: (AVCaptureDevice*)dev;


// Private delegate method for same:
- (void)focusRectSelected: (NSorUIRect)theRect;

/// Delegate methods for QTCaptureVideoPreviewOutput.
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection;

/// Delegate methods for QTCaptureVideoPreviewOutput.
- (void)captureOutput:(AVCaptureOutput *)captureOutput
  didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection;
@end
