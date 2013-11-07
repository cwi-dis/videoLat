#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "genQRcodes.h"
#import "Manager.h"


@interface MyQTCaptureView : NSView
{
	NSPoint downPoint;
    id delegate;
}
@property (retain) id delegate;

- (void)mouseDown: (NSEvent *)theEvent;
- (void)mouseUp: (NSEvent *)theEvent;

@end

@interface iSight : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
    IBOutlet id <MeasurementInputManagerProtocol> manager;
    IBOutlet MyQTCaptureView *selfView;
    AVCaptureVideoPreviewLayer *selfLayer;
    AVCaptureVideoDataOutput *outputCapturer;
	AVCaptureSession *session;
    dispatch_queue_t sampleBufferQueue;
	float xFactor, yFactor;
}

- (bool)available;
- (AVCaptureDevice*)deviceWithName: (NSString*)name;
- (NSArray*) deviceNames;
- (void)switchToDevice: (AVCaptureDevice*)dev;
- (void)switchToDeviceWithName: (NSString *)name;



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