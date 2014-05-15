//
//  MeasurementTypeView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>
#import "RunStatusView.h"
#import "RunCollector.h"

@interface RunTypeView : NSView {
	NSArray *runManagerNibObjects;	// Storage for toplevel object references from loaded nibfiles
    BOOL wasAwokenFromNib;
}
@property(weak) IBOutlet NSPopUpButton *bType;
@property(strong) IBOutlet id runManager;
@property(strong) IBOutlet NSView *selectionView;
@property(strong) IBOutlet NSView *outputView;
@property(weak) IBOutlet RunStatusView *statusView;
@property(weak) IBOutlet RunCollector *collector;
@property(weak) IBOutlet Document *document;
@property(weak) IBOutlet NSView *selectionContainerView;
@property(weak) IBOutlet NSView *outputContainerView;

- (void)terminate;
- (IBAction)typeChanged: (id)sender;
- (IBAction)stopMeasuring: (id)sender;

@end
