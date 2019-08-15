///
///  @file HardwareInput.h
///  @brief Video camera driver using AVFoundation.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//
#import "protocols.h"

///
/// Class that implements InputDeviceProtocol (and ClockProtocol) for hardware input.
///
@interface HardwareInput : NSObject <ClockProtocol, InputDeviceProtocol> {
	BOOL capturing;
}
@property(weak) IBOutlet id <RunInputManagerProtocol> manager;

+ (NSArray*) deviceNames;
- (uint64_t)now;

- (bool)available;
- (NSArray*) deviceNames;
- (BOOL)switchToDeviceWithName: (NSString *)name;
- (void) startCapturing: (BOOL) showPreview;
- (void) pauseCapturing: (BOOL) pause;
- (void) stopCapturing;

- (void) stop;

@end
