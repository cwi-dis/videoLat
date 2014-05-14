//
//  OutputView.h
//  macMeasurements
//
//  Created by Jack Jansen on 01-09-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"

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
