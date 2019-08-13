///
///  @file HardwareOutputView.h
///  @brief NSView subclass that shows light/darkness for hardware devices.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"

///
/// Subclass of NSView that adheres to OutputDeviceProtocol and shows currently
/// selected hardware output device.
///
@interface HardwareOutputView : NSView <OutputDeviceProtocol> {
}

@property(weak) IBOutlet NSButton *bOutputValue;    //!< UI element that shows current output value

@property(weak) NSObject <HardwareLightProtocol> *device;  //!< our output device (assigned by HardwareRunManager)

- (void) showNewData;   //!< Called when new data should be shown
 
@end
