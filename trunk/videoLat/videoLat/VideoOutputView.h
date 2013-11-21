//
//  OutputView.h
//  macMeasurements
//
//  Created by Jack Jansen on 01-09-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"

@interface VideoOutputView : NSView <OutputVideoViewProtocol> {
    IBOutlet id <RunOutputManagerProtocol> manager;
    bool newOutputDone;
	BOOL mirrored;
	NSString *deviceID;
}

@property BOOL mirrored;
@property BOOL visible;
@property (readonly) NSString *deviceID;

- (void) showNewData;

- (void)drawRect:(NSRect)dirtyRect;
	
// Refresh callback
- (void)refreshCallback: (CGRectCount)count rects: (const CGRect *)rectArray;

- (IBAction)toggleFullscreen: (NSMenuItem*) sender;
 
@end
