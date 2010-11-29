#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "genQRcodes.h"
#import "findQRcodes.h"
#import "output.h"
#import "SettingsView.h"
#import "Manager.h"

@interface MyQTCaptureView : QTCaptureView
{
	NSPoint downPoint;
}

- (void)mouseDown: (NSEvent *)theEvent;
- (void)mouseUp: (NSEvent *)theEvent;

@end

@interface iSight : NSObject {
    IBOutlet SettingsView *settings;
    IBOutlet Manager *manager;
    IBOutlet QTCaptureView *selfView;
    QTCaptureVideoPreviewOutput *outputCapturer;
	QTCaptureSession *session;
	float xFactor, yFactor;
}

- (bool)available;
- (QTCaptureDevice*)deviceWithName: (NSString*)name;
- (NSArray*) deviceNames;
- (void)switchToDevice: (QTCaptureDevice*)dev;


// Delegate method for QTCaptureView:
- (CIImage *)view:(QTCaptureView *)view willDisplayImage:(CIImage *)image;

// Private delegate method for same:
- (void)focusRectSelected: (NSRect)theRect;

// Delegate method for QTCaptureVideoPreviewOutput:
- (void)captureOutput:(QTCaptureOutput *)captureOutput 
    didOutputVideoFrame:(CVImageBufferRef)videoFrame
    withSampleBuffer:(QTSampleBuffer *)sampleBuffer
    fromConnection:(QTCaptureConnection *)connection;
@end