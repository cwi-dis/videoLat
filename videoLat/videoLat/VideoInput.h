#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "genQRcodes.h"


@interface VideoInputView : NSView
{
	NSPoint downPoint;
}
@property (retain) IBOutlet id delegate;
@property (retain) IBOutlet NSButton *visibleButton;

- (IBAction)visibleChanged:(id)sender;
- (void)mouseDown: (NSEvent *)theEvent;
- (void)mouseUp: (NSEvent *)theEvent;

@end

@interface VideoInput : NSObject <InputCaptureProtocol, AVCaptureVideoDataOutputSampleBufferDelegate> {
    IBOutlet id <RunInputManagerProtocol> manager;
    IBOutlet VideoInputView *selfView;
    AVCaptureVideoPreviewLayer *selfLayer;
    AVCaptureVideoDataOutput *outputCapturer;
	AVCaptureSession *session;
    dispatch_queue_t sampleBufferQueue;
	float xFactor, yFactor;
	NSString *deviceID;
	NSString *deviceName;
}
@property (readonly) NSString *deviceID;
@property (readonly) NSString *deviceName;

- (bool)available;
- (AVCaptureDevice*)_deviceWithName: (NSString*)name;
- (NSArray*) deviceNames;
- (void)_switchToDevice: (AVCaptureDevice*)dev;
- (BOOL)switchToDeviceWithName: (NSString *)name;
- (void) startCapturing;
- (void) stopCapturing;



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