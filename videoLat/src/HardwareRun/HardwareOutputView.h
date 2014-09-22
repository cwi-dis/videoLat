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

@property BOOL mirrored; // Ignored
@property(readonly) NSString *deviceID;
@property(readonly) NSString *deviceName;
@property(weak) IBOutlet NSObject <HardwareLightProtocol> *device;
@property(weak) IBOutlet NSButton *bOutputValue;

- (void) showNewData;
 
@end
