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

@class BaseRunManager;
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
@interface RunManagerView : NSorUIView {
}
@property(strong) IBOutlet BaseRunManager *runManager;			//!< Set by  measurement type NIB: reference to corresponding BaseRunManager subclass
@property(strong) IBOutlet NSorUIView *selectionView;	//!< Set by  measurement type NIB: reference to the view where user can select input source.
@property(strong) IBOutlet NSorUIView *outputView;		//!< Set by  measurement type NIB: reference to the view where output is shown
@property(weak) IBOutlet RunStatusView *statusView;	//!< Set by our NIB: reference to the runtime status view (average/count)

- (void)terminate;						//!< Unused?

@end
