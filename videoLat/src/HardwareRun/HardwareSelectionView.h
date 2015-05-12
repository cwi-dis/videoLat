///
///  @file HardwareSelectionView.h
///  @brief UI to select Arduino/Labjack hardware device.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "protocols.h"

///
/// Subclass of NSView that allows user to select camera to use as input source
/// and possibly the calibration run to base the new measurement run on.
/// This is a separate class because it is shared among the various video-based
/// measurement runs.
///
@interface HardwareSelectionView : NSView<SelectionView>
@property(weak) IBOutlet NSPopUpButton *bDevices;   //!< UI element: all available hardware
@property(weak) IBOutlet NSPopUpButton *bBase;      //!< UI element: available calibration runs
@property(weak) IBOutlet NSButton *bPreRun;         //!< UI element: start preparing a measurement run
@property(weak) IBOutlet NSObject <SelectionViewDelegate> *selectionDelegate;	//!< Object we send feedback to.

- (IBAction)deviceChanged: (id) sender;     //!< Called when the user makes a new selection in bDevices

@end