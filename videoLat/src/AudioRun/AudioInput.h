///
///  @file AudioInput.h
///  @brief UI to select audio input device.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//
#import <AVFoundation/AVFoundation.h>
#import "protocols.h"

///
/// Class that implements InputDeviceProtocol (and ClockProtocol) for audio input, using
/// AVCapture to capture an audio stream from a microphone or other audio input.
///

@interface AudioInput : NSObject <ClockProtocol, InputDeviceProtocol, AVCaptureAudioDataOutputSampleBufferDelegate> {
    AVCaptureAudioDataOutput *outputCapturer;
	AVCaptureSession *session;
    dispatch_queue_t sampleBufferQueue;
#ifdef xxxjacknotneeded
	NSString *deviceID;
	NSString *deviceName;
#endif
#ifdef WITH_DEVICE_CLOCK
    CMClockRef clock;
#endif
    uint64_t epoch;
	BOOL capturing;
}
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
