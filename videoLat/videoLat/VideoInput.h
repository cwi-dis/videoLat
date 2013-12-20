#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "genQRcodes.h"


@interface VideoInputView : NSView
{
	NSPoint downPoint;
}
@property (weak) IBOutlet id delegate;
@property (weak) IBOutlet NSButton *visibleButton;

- (IBAction)visibleChanged:(id)sender;
- (void)mouseDown: (NSEvent *)theEvent;
- (void)mouseUp: (NSEvent *)theEvent;

@end

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