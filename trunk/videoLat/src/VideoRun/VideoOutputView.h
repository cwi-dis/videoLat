//
//  OutputView.h
//  macMeasurements
//
//  Created by Jack Jansen on 01-09-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"

///
/// Subclass of NSView that displays newly generated images (black/white or QRcode)
/// by asking the run manager for new data.
///
/// The object also records the output device ID, by determining on which display it is
/// being shown, and communicates this to the run manager.
///
@interface VideoOutputView : NSView <OutputViewProtocol> {
	BOOL mirrored;
	NSString *deviceID;
}

@property BOOL mirrored;                    //!< Set to true by manager if image should be displayed mirrored
@property(readonly) NSString *deviceID;     //!< Unique string that identifies the output device
@property(readonly) NSString *deviceName;	//!< Human-readable string that identifies the output device
@property(weak) IBOutlet id <RunOutputManagerProtocol> manager; //!< Set by NIB: our run manager
@property(weak) IBOutlet NSTextField *bOutputName;              //!< UI element: shows our device name
/// Internal: the screen our window was on during the last redraw.
/// Used to update deviceID and deviceName when the user moves our window to a different screen.
@property(weak) NSScreen *oldScreen;

- (void) showNewData;

- (void)drawRect:(NSRect)dirtyRect;
 
@end
