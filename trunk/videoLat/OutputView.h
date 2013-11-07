//
//  OutputView.h
//  macMeasurements
//
//  Created by Jack Jansen on 01-09-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Manager.h"
#import "protocols.h"

@interface OutputView : NSView <OutputViewProtocol> {
    IBOutlet id <MeasurementOutputManagerProtocol> manager;
    bool newOutputDone;
	BOOL mirrored;
}

@property BOOL mirrored;
@property BOOL visible;

- (void) showNewData;

- (void)drawRect:(NSRect)dirtyRect;
	
// Refresh callback
- (void)refreshCallback: (CGRectCount)count rects: (const CGRect *)rectArray;

- (IBAction)toggleFullscreen: (NSMenuItem*) sender;
 
@end
