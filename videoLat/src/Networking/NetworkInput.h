///
///  @file NetworkInput.h
///  @brief Implements getting measurement samples from another videoLat on the network.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//
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