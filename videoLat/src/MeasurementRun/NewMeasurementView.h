///
///  @file NewMeasurementView.h
///  @brief Holds NewMeasurementViewController object definition (OSX only).
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Cocoa/Cocoa.h>
#import "RunManagerView.h"
#import "DownloadCalibrationViewController.h"

///
/// ViewController for window that allows selecting measurement type and starting it.
///
@interface NewMeasurementViewController : NSViewController<NSWindowDelegate> {
    NSArray *runManagerNibObjects;	//!< internal: storage for toplevel object references from loaded nibfiles
}

@property(weak) IBOutlet NSPopUpButton *bType;              //!< Set by our NIB: reference to the measurement type button
@property(weak) IBOutlet NSWindow *measurementWindow;       //!< Set by measurement NIB (on file owner): its window
@property(weak) IBOutlet RunManagerView *runManagerView;    //!< Set by measurement NIB (on file owner): its view
@property(weak) IBOutlet DownloadCalibrationViewController *downloadCalibrationViewController;
@property(weak) IBOutlet NSTabView *tabView;

- (IBAction)doMeasurement:(id)sender;	//!< Callback from run button.
- (void)_updateMeasurementTypes;	//!< Internal: populate bType.
@end
