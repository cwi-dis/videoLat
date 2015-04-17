#import "protocols.h"
#import "genQRcodes.h"


///
/// Class that implements InputCaptureProtocol (and ClockProtocol) for data that
/// is actually captured remotely, and for which the data is sent to us over the network.
///
@interface NetworkInput : NSObject <ClockProtocol, InputCaptureProtocol> {
}
@property (readonly) NSString *deviceID;
@property (readonly) NSString *deviceName;
@property(weak) IBOutlet id <RunInputManagerProtocol> manager;

- (uint64_t)now;
- (void) startCapturing: (BOOL) showPreview;
- (void) stopCapturing;
- (void) stop;


@end