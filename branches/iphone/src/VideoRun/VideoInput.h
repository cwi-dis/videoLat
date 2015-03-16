#import <AVFoundation/AVFoundation.h>
#import "protocols.h"
#ifndef WITH_UIKIT_TEMP
#import "genQRcodes.h"
#endif

#define WITH_STATISTICS

///
/// Subclass of NSView that shows preview of what the camera has captured, helper class
/// for VideoInput class.
///
@interface VideoInputView : NSorUIView
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

+ (NSArray *) allDeviceTypeIDs;

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
- (void)focusRectSelected: (NSorUIRect)theRect;

// Delegate methods for QTCaptureVideoPreviewOutput:
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection;
- (void)captureOutput:(AVCaptureOutput *)captureOutput
  didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection;
@end