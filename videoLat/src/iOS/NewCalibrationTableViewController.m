//
//  NewCalibrationTableViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 25/03/15.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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
		@"Camera Calibrate using Other Device",
		@"Screen Calibrate using Other Device"
		];
}


@end
