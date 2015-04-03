//
//  NewCalibrationTableViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 25/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "NewCalibrationTableViewController.h"

@implementation NewCalibrationTableViewController

- (NSArray *)measurementNames
{
	return @[
		@"Video Roundtrip Calibrate",
		@"Audio Roundtrip Calibrate",
		@"Camera Calibrate using Calibrated Screen",
		@"Screen Calibrate using Calibrated Camera",
		@"Camera Calibrate using Remote Calibrated Screen (Slave,Client)",
		@"Screen Calibrate using Remote Calibrated Camera (Master,Server)"
		];
}


@end
