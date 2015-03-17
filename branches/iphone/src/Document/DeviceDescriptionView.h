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


@interface DeviceDescriptionView : NSorUIView
@property(weak) IBOutlet NSorUITextField *bMachineTypeID; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bMachine; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bLocation; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bDevice; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bCalibration; //!< Reference to UI element
@property(weak) IBOutlet NSorUIButton *bOpenCalibration;

@property(weak) DeviceDescription *modelObject;

- (IBAction)update:(id)sender;
@end
