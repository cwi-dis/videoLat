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
@interface VideoSelectionView
#ifdef WITH_UIKIT
 : UIView<SelectionView>
#else
 : NSView<SelectionView>
#endif


#ifdef WITH_UIKIT
@property(weak) IBOutlet UIButton *bSwitchDevice;   //!< UI element: switch to next available cameras
@property(weak) IBOutlet UILabel *bDeviceName;		//!< UI element: current selected camera
@property(weak) IBOutlet UIView *cameraPreview;		//!< UI element: preview of current camera
@property(weak) IBOutlet UIPickerView *bBase;      //!< UI element: available calibration runs
@property(weak) IBOutlet UIButton *bPreRun;         //!< UI element: start preparing a measurement run
#else
@property(weak) IBOutlet NSPopUpButton *bDevices;   //!< UI element: all available cameras
@property(weak) IBOutlet NSPopUpButton *bBase;      //!< UI element: available calibration runs
@property(weak) IBOutlet NSButton *bPreRun;         //!< UI element: start preparing a measurement run
#endif
@property(weak) IBOutlet VideoInput *inputHandler;  //!< Input handler, will be told about camera changes
@property(weak) IBOutlet NSObject <SelectionViewDelegate> *selectionDelegate;

- (IBAction)deviceChanged: (id) sender;     //!< Called when the user makes a new selection in bCameras
- (void)_updateCameraNames: (NSNotification*) notification; //!< Called by notification manager when a camera is attached/removed.
- (void)_reselectCamera: (NSString *)name;  //!< Internal: try to re-select our camera on camera change

- (void)setBases: (NSArray *)baseNames;
- (void)disableBases;
- (NSString *)baseName;				//!< Returns name of selected base measurement
- (NSString *)deviceName;			//!< Returns name of selected input device
#ifdef WITH_UIKIT
- (IBAction)selectNextCamera: (id)sender;
#endif
@end
