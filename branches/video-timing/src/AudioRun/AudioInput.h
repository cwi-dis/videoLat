#import <AVFoundation/AVFoundation.h>
#import "protocols.h"

///
/// Class that implements InputCaptureProtocol (and ClockProtocol) for audio input, using
/// AVCapture to capture an audio stream from a microphone or other audio input.
///

@interface AudioInput : NSObject <ClockProtocol, InputCaptureProtocol, AVCaptureAudioDataOutputSampleBufferDelegate> {
    AVCaptureAudioDataOutput *outputCapturer;
	AVCaptureSession *session;
    dispatch_queue_t sampleBufferQueue;
	NSString *deviceID;
	NSString *deviceName;
#ifdef WITH_DEVICE_CLOCK
    CMClockRef clock;
#endif
    uint64_t epoch;
	BOOL capturing;
}
@property (readonly) NSString *deviceID;
@property (readonly) NSString *deviceName;
@property(weak) IBOutlet id <RunInputManagerProtocol> manager;
#ifdef WITH_UIKIT
@property(weak) IBOutlet UIProgressView *bInputValue;
#else
@property(weak) IBOutlet NSLevelIndicator *bInputValue;
#endif

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
@end