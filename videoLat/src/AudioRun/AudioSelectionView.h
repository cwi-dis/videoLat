///
///  @file AudioSelectionView.h
///  @brief UI to select audio input device.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "compat.h"
#import "AudioInput.h"
#ifdef WITH_UIKIT
#import "InputSelectionView.h"
#endif

///
/// Subclass of NSView, allows the user to select the audio input device.
///
@interface AudioSelectionView
#ifdef WITH_UIKIT
: InputSelectionView
#else
: NSView<InputSelectionView>
#endif

#ifdef WITH_UIKIT
@property(weak) IBOutlet UILabel *bOutputDeviceName;
#else
@property(weak) IBOutlet NSPopUpButton *bDevices;  //!< UI element: all available audio input sources
@property(weak) IBOutlet NSPopUpButton *bBase;          //!< UI element: available calibration runs
@property(weak) IBOutlet NSButton *bPreRun;             //!< UI element: start a measurement run
#endif
@property(weak) IBOutlet AudioInput *inputHandler;      //!< Input handler, will be told about camera changes


- (void)_updateDeviceNames: (NSNotification*) notification; //!< Called by notification manager when audio device configuration changes.
#ifdef WITH_APPKIT
- (IBAction)deviceChanged: (id) sender;                  //!< Called when the user makes a new selection in bInputDevices
- (void)_reselectInput: (NSString *)name;               //!< Internal: try to re-select our input on device change
#endif

@end
