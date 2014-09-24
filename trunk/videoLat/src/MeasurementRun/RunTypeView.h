///
///  @file RunTypeView.h
///  @brief Defines RunTypeView object.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "RunStatusView.h"
#import "RunCollector.h"

///
/// Subclass of NSView that allows for the selection of the type of measurement run.
/// This is the master object for controlling a measurement run, and is instantiated
/// from the NewMeasurement.xib NIB file.
///
/// When a new type is selected (and when this view is initially loaded) it then loads
/// the NIBfile corresponding to the selected measurement type. That NIB file will
/// then populate the IBOutlets of this view with the various views and objects that
/// allow the measurement run to proceed.
///
@interface RunTypeView : NSView {
	NSArray *runManagerNibObjects;	//!< internal: storage for toplevel object references from loaded nibfiles
    BOOL wasAwokenFromNib;			//!< Internal: make sure we do some initializations exactly once.
}
@property(weak) IBOutlet NSPopUpButton *bType;		//!< Set by our NIB: reference to the measurement type button
@property(strong) IBOutlet id runManager;			//!< Set by  measurement type NIB: reference to the measurement type button
@property(strong) IBOutlet NSView *selectionView;	//!< Set by  measurement type NIB: reference to the view where user can select input source.
@property(strong) IBOutlet NSView *outputView;		//!< Set by  measurement type NIB: reference to the view where output is shown
@property(weak) IBOutlet RunStatusView *statusView;	//!< Set by our NIB: reference to the runtime status view (average/count)
@property(weak) IBOutlet RunCollector *collector;	//!< Set by ??? NIB: reference to the measurement data collector
@property(weak) IBOutlet Document *document;		//!< Set by our NIB: reference to the document we are creating
@property(weak) IBOutlet NSView *selectionContainerView;	//!< Set by our NIB: container view for measurement  selectionView
@property(weak) IBOutlet NSView *outputContainerView;	//!< Set by our NIB: container view for measurement outputView

- (void)terminate;						//!< Unused?
- (IBAction)typeChanged: (id)sender;	//!< Called on awakeFromNIB or when user selects a different measurement type.
- (IBAction)stopMeasuring: (id)sender;	//!< Called when user presses "stop" button

@end
