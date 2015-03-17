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
@property(weak) IBOutlet UITextField *bMachineTypeID; //!< Reference to UI element
@property(weak) IBOutlet UITextField *bMachine; //!< Reference to UI element
@property(weak) IBOutlet UITextField *bLocation; //!< Reference to UI element
@property(weak) IBOutlet UITextField *bDevice; //!< Reference to UI element
@property(weak) IBOutlet UITextField *bCalibration; //!< Reference to UI element
@property(weak) IBOutlet UIButton *bOpenCalibration;
#else
@property(weak) IBOutlet NSTextField *bMachineTypeID; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bMachine; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bLocation; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDevice; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bCalibration; //!< Reference to UI element
@property(weak) IBOutlet NSButton *bOpenCalibration;
#endif

@property(weak) DeviceDescription *modelObject;

- (IBAction)update:(id)sender;
@end
