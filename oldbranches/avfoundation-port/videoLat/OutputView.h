//
//  OutputView.h
//  macMeasurements
//
//  Created by Jack Jansen on 01-09-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SettingsView.h"
#import "Manager.h"

@interface OutputView : NSView {
    IBOutlet SettingsView *settings;
    IBOutlet id manager;
    bool newOutputDone;
}

- (void)drawRect:(NSRect)dirtyRect;
	
// Refresh callback
- (void)refreshCallback: (CGRectCount)count rects: (const CGRect *)rectArray;

- (IBAction)toggleFullscreen: (NSMenuItem*) sender;
 
@end
