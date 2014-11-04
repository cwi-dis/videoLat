//
//  HardwareOutputView.h
//  videoLat
//
//  Created by Jack Jansen on 7/01/14.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"

///
/// Subclass of NSView that adheres to OutputViewProtocol and shows currently
/// selected hardware output device.
///
@interface HardwareOutputView : NSView <OutputViewProtocol> {
}

@property BOOL mirrored;                    //!< Unused
@property(readonly) NSString *deviceID;     //!< accessor for device.deviceID
@property(readonly) NSString *deviceName;	//!< accessor for device.deviceName
@property(weak) IBOutlet NSButton *bOutputValue;    //!< UI element that shows current output value

@property NSObject <HardwareLightProtocol> *device;  //!< our output device (assigned by HardwareRunManager)

- (void) showNewData;   //!< Called when new data should be shown
 
@end
