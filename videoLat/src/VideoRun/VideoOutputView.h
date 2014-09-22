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

@property BOOL mirrored;
@property BOOL visible;
@property(readonly) NSString *deviceID;
@property(weak) IBOutlet id <RunOutputManagerProtocol> manager;
@property(weak) IBOutlet NSTextField *bOutputName;
@property(weak) NSScreen *oldScreen;

- (void) showNewData;

- (void)drawRect:(NSRect)dirtyRect;
	
- (IBAction)toggleFullscreen: (NSMenuItem*) sender;
 
@end
