//
//  DeviceDescriptionView.m
//  videoLat
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "DeviceDescriptionView.h"
#import "MeasurementDataStore.h"

@implementation DeviceDescriptionView
@synthesize bMachineTypeID;
@synthesize bMachine;
@synthesize bLocation;
@synthesize bDevice;
@synthesize bCalibration;
@synthesize bOpenCalibration;
@synthesize modelObject;

#ifdef WITH_UIKIT
// Gross....
#define stringValue text
#endif

- (void)drawRect:(NSorUIRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void) update: (id)sender
{
    if (bMachineTypeID) bMachineTypeID.stringValue = modelObject.machineTypeID;
    if (bMachine) bMachine.stringValue = modelObject.machine;
    if (bLocation) bLocation.stringValue = modelObject.location;
    if (bDevice) bDevice.stringValue = modelObject.device;
    if (bCalibration) {
        NSString *val = @"";
        if (modelObject.calibration) {
            [bOpenCalibration setEnabled:YES];
            val = modelObject.calibration.descriptiveName;
        } else {
            [bOpenCalibration setEnabled:NO];
            val = @"";
        }
        bCalibration.stringValue = val;
    }
}

@end
