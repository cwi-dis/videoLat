///
///  @file HardwareOutputView.h
///  @brief NSView subclass that shows light/darkness for hardware devices.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"
#import "HardwareInput.h"

///
/// Subclass of NSView that adheres to OutputDeviceProtocol and shows currently
/// selected hardware output device.
///
@interface HardwareOutputView : NSView <OutputDeviceProtocol> {
}

@property(weak) IBOutlet NSButton *bOutputValue;    //!< UI element that shows current output value
@property(weak) IBOutlet id <RunOutputManagerProtocol> manager; //!< Set by NIB: our run manager
@property(weak) IBOutlet HardwareInput *hardwareInputHandler;  //!< our output device is actually managed by the combined input/output driver

- (void) showNewData;   //!< Called when new data should be shown
 
@end
