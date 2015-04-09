//
//  DeviceDescriptionView.h
//  videoLat
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "compat.h"
#import "DeviceDescription.h"


@interface DeviceDescriptionView
#ifdef WITH_UIKIT
: UIView
#else
: NSView
#endif
#ifdef WITH_UIKIT
@property(weak) IBOutlet UILabel *bMachineTypeID; //!< Reference to UI element
@property(weak) IBOutlet UILabel *bMachine; //!< Reference to UI element
@property(weak) IBOutlet UILabel *bLocation; //!< Reference to UI element
@property(weak) IBOutlet UILabel *bDevice; //!< Reference to UI element
@property(weak) IBOutlet UILabel *bCalibration; //!< Reference to UI element
@property(weak) IBOutlet UIButton *bOpenCalibration; //!< Reference to UI element
@property(weak) IBOutlet UILabel *bCalibrationLabel; //!< Reference to UI element
#else
@property(weak) IBOutlet NSTextField *bMachineTypeID; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bMachine; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bLocation; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDevice; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bCalibration; //!< Reference to UI element
@property(weak) IBOutlet NSButton *bOpenCalibration; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bCalibrationLabel; //!< Reference to UI element
#endif

@property(weak) DeviceDescription *modelObject;

- (IBAction)update:(id)sender;
@end
