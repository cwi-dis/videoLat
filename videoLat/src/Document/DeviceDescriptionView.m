//
//  DeviceDescriptionView.m
//  videoLat
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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
@synthesize bCalibrationLabel;
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
    if (bMachineTypeID) {
		if (modelObject.os)
			bMachineTypeID.stringValue = [NSString stringWithFormat:@"%@ (%@)", modelObject.machineTypeID, modelObject.os];
		else
			bMachineTypeID.stringValue = modelObject.machineTypeID;
	}
    if (bMachine) bMachine.stringValue = modelObject.machine;
    if (bLocation) bLocation.stringValue = modelObject.location;
    if (bDevice) bDevice.stringValue = modelObject.device;
    if (bCalibration) {
        if (modelObject.calibration) {
            [bOpenCalibration setEnabled:YES];
			bOpenCalibration.hidden = NO;
			bCalibration.hidden = NO;
			bCalibrationLabel.hidden = NO;
            bCalibration.stringValue = modelObject.calibration.descriptiveName;
        } else {
            [bOpenCalibration setEnabled:NO];
			bOpenCalibration.hidden = YES;
			bCalibration.hidden = YES;
			bCalibrationLabel.hidden = YES;
            bCalibration.stringValue = @"";
        }
    }
}

@end
