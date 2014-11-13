//
//  MeasurementVideoSelectionView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>
#import "AudioInput.h"

///
/// Subclass of NSView, allows the user to select the audio input device.
///
@interface AudioSelectionView : NSView<SelectionView>
@property(weak) IBOutlet NSPopUpButton *bDevices;  //!< UI element: all available audio input sources
@property(weak) IBOutlet NSPopUpButton *bBase;          //!< UI element: available calibration runs
@property(weak) IBOutlet NSButton *bPreRun;             //!< UI element: start a measurement run
@property(weak) IBOutlet NSButton *bRun;                //!< UI element: start preparing a measurement run
@property(weak) IBOutlet AudioInput *inputHandler;      //!< Input handler, will be told about camera changes
@property(weak) IBOutlet NSObject<RunInputManagerProtocol> *manager;         //!< Manager, will be told about hardware changes

- (void)_updateDeviceNames: (NSNotification*) notification; //!< Called by notification manager when audio device configuration changes.
- (IBAction)deviceChanged: (id) sender;                  //!< Called when the user makes a new selection in bInputDevices
- (void)_reselectInput: (NSString *)name;               //!< Internal: try to re-select our input on device change

@end
