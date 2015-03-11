//
//  MeasurementVideoSelectionView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>
#import "VideoInput.h"

///
/// Subclass of NSView that allows user to select camera to use as input source
/// and possibly the calibration run to base the new measurement run on.
/// This is a separate class because it is shared among the various video-based
/// measurement runs.
///
@interface VideoSelectionView : NSView<SelectionView>
@property(weak) IBOutlet NSPopUpButton *bDevices;   //!< UI element: all available cameras
@property(weak) IBOutlet NSPopUpButton *bBase;      //!< UI element: available calibration runs
@property(weak) IBOutlet NSButton *bPreRun;         //!< UI element: start preparing a measurement run
@property(weak) IBOutlet NSButton *bRun;            //!< UI element: start a measurement run
@property(weak) IBOutlet VideoInput *inputHandler;  //!< Input handler, will be told about camera changes
@property(weak) IBOutlet NSObject<RunInputManagerProtocol> *manager;         //!< Manager, will be told about hardware changes

- (IBAction)deviceChanged: (id) sender;     //!< Called when the user makes a new selection in bCameras
- (void)_updateCameraNames: (NSNotification*) notification; //!< Called by notification manager when a camera is attached/removed.
- (void)_reselectCamera: (NSString *)name;  //!< Internal: try to re-select our camera on camera change

@end
