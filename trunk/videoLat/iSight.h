#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "genQRcodes.h"
#import "findQRcodes.h"
#import "output.h"
#import "SettingsView.h"
#import "Manager.h"

@interface iSight : NSObject {
    IBOutlet SettingsView *settings;
    IBOutlet Manager *manager;
    IBOutlet QTCaptureView *selfView;
    QTCaptureVideoPreviewOutput *outputCapturer;
	QTCaptureSession *session;
}

- (bool)available;
- (QTCaptureDevice*)deviceWithName: (NSString*)name;
- (NSArray*) deviceNames;
- (void)switchToDevice: (QTCaptureDevice*)dev;


// Delegate method for QTCaptureView:
- (CIImage *)view:(QTCaptureView *)view willDisplayImage:(CIImage *)image;


// Delegate method for QTCaptureVideoPreviewOutput:
- (void)captureOutput:(QTCaptureOutput *)captureOutput 
    didOutputVideoFrame:(CVImageBufferRef)videoFrame
    withSampleBuffer:(QTSampleBuffer *)sampleBuffer
    fromConnection:(QTCaptureConnection *)connection;
@end