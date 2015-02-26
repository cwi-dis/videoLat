#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "genQRcodes.h"

@interface AudioInput : NSObject <ClockProtocol, InputCaptureProtocol, AVCaptureAudioDataOutputSampleBufferDelegate> {
    AVCaptureAudioDataOutput *outputCapturer;
	AVCaptureSession *session;
    dispatch_queue_t sampleBufferQueue;
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
@property(weak) IBOutlet NSLevelIndicator *bInputValue;
@property(weak) IBOutlet id <RunInputManagerProtocol> manager;

- (uint64_t)now;
- (bool)available;
- (AVCaptureDevice*)_deviceWithName: (NSString*)name;
- (NSArray*) deviceNames;
- (void)_switchToDevice: (AVCaptureDevice*)dev;
- (BOOL)switchToDeviceWithName: (NSString *)name;
- (void) startCapturing: (BOOL) showPreview;
- (void) stopCapturing;
- (void) stop;
@end