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

///
/// Subclass of NSView that allows for the selection of the type of measurement run.
/// When a new type is selected (and when the view is initially loaded) it then loads
/// the NIBfile corresponding to the selected measurement type. This NIB file will
/// then populate the IBOutlets of this view with the various views and objects that
/// allow the measurement run to proceed.
///
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
