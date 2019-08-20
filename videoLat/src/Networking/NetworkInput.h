///
///  @file NetworkInput.h
///  @brief Implements getting measurement samples from another videoLat on the network.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//
#import "protocols.h"
#import "BaseRunManager.h"

///
/// Class that implements InputDeviceProtocol (and ClockProtocol) for data that
/// is actually captured remotely, and for which the data is sent to us over the network.
///
@interface NetworkInput : NSObject <ClockProtocol, InputDeviceProtocol> {
}
@property(weak) IBOutlet BaseRunManager *manager;           //!< Our input manager
@property(weak) IBOutlet BaseRunManager *outputManager;     //!< Our output manager, if different
@property(weak) IBOutlet NSObject<ClockProtocol> *clock;    //!< Our clock, if not ourselves

- (uint64_t)now;
- (void) startCapturing: (BOOL) showPreview;
- (void) stopCapturing;
- (void) stop;


@end
