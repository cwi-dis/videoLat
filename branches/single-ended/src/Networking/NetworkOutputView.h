//
//  NetworkOutputView.h
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
@interface NetworkOutputView : NSView <OutputViewProtocol, NetworkViewProtocol> {
}

@property BOOL mirrored;                    //!< Unused
@property(readonly) NSString *deviceID;     //!< accessor for device.deviceID
@property(readonly) NSString *deviceName;	//!< accessor for device.deviceName

- (void) showNewData;   //!< Called when new data should be shown

- (void) reportClient: (NSString *)ip port: (int)port isUs: (BOOL) us;
- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us;


@end
