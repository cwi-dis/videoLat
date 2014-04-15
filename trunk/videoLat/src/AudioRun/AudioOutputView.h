//
//  HardwareOutputView.h
//  videoLat
//
//  Created by Jack Jansen on 7/01/14.
//  Copyright (c) 2014 CWI. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"

@interface AudioOutputView : NSView <OutputViewProtocol> {
}

@property BOOL mirrored; // Ignored
@property(readonly) NSString *deviceID;
@property(readonly) NSString *deviceName;
//@property(weak) IBOutlet NSObject <HardwareLightProtocol> *device;
@property(weak) IBOutlet NSLevelIndicator *bOutputValue;

- (void) showNewData;
 
@end
