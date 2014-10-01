#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "genQRcodes.h"

#define WITH_STATISTICS

///
/// Subclass of NSView that shows preview of what the camera has captured, helper class
/// for VideoInput class.
///
@interface VideoInputView : NSView
{
	NSPoint downPoint;      //!< Internal: position of mouse down event
}
@property (weak) IBOutlet id delegate;  //!< Set by NIB: corresponding VideoInput object
@property (weak) IBOutlet NSButton *visibleButton;  //!< UI element, allows user to toggle video preview

- (IBAction)visibleChanged:(id)sender;  //!< Called when user toggles visibleButton
- (void)mouseDown: (NSEvent *)theEvent; //!< Mouse event handler, to allow selecting a rectangular area
- (void)mouseUp: (NSEvent *)theEvent;   //!< Mouse event handler, to allow selecting a rectangular area

@end

///
/// Class that implements InputCaptureProtocol (and ClockProtocol) for video input, using
/// AVCapture to capture a video stream from a camera.
///
@interface VideoInput : NSObject <ClockProtocol, InputCaptureProtocol, AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureVideoPreviewLayer *selfLayer;
    AVCaptureVideoDataOutput *outputCapturer;
	AVCaptureSession *session;
    dispatch_queue_t sampleBufferQueue;
	float xFactor, yFactor;
	NSString *deviceID;
	NSString *deviceName;
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
    CMClockRef clock;
#endif
    uint64_t epoch;
	BOOL capturing;
#ifdef WITH_STATISTICS
	// Statistics
	uint64_t firstTimeStamp;
	uint64_t lastTimeStamp;
	int nFrames;
	int nEarlyDrops;
	int nLateDrops;
#endif
}
@property (readonly) NSString *deviceID;
@property (readonly) NSString *deviceName;
@property(weak) IBOutlet id <RunInputManagerProtocol> manager;
@property(weak) IBOutlet VideoInputView *selfView;

- (uint64_t)now;
- (bool)available;
- (AVCaptureDevice*)_deviceWithName: (NSString*)name;
- (NSArray*) deviceNames;
- (void)_switchToDevice: (AVCaptureDevice*)dev;
- (BOOL)switchToDeviceWithName: (NSString *)name;
- (void) startCapturing: (BOOL) showPreview;
- (void) stopCapturing;
- (void) stop;




#ifdef NOTYETFORAVFOUNDATION
// Delegate method for QTCaptureView:
- (CIImage *)view:(QTCaptureView *)view willDisplayImage:(CIImage *)image;
#endif

// Private delegate method for same:
- (void)focusRectSelected: (NSRect)theRect;

// Delegate methods for QTCaptureVideoPreviewOutput:
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection;
- (void)captureOutput:(AVCaptureOutput *)captureOutput
  didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection;
@end