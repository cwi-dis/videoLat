#import "protocols.h"
#import "genQRcodes.h"


///
/// Class that implements InputCaptureProtocol (and ClockProtocol) for video input, using
/// AVCapture to capture a video stream from a camera.
///
@interface NetworkInput : NSObject <ClockProtocol, InputCaptureProtocol> {
}
@property (readonly) NSString *deviceID;
@property (readonly) NSString *deviceName;
@property(weak) IBOutlet id <RunInputManagerProtocol> manager;

- (uint64_t)now;
//- (bool)available;
//- (NSArray*) deviceNames;
//- (void)_switchToDevice: (AVCaptureDevice*)dev;
//- (BOOL)switchToDeviceWithName: (NSString *)name;
- (void) startCapturing: (BOOL) showPreview;
- (void) stopCapturing;
- (void) stop;


@end