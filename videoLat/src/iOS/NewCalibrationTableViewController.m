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
        @"Transmission Calibrate using Other Device",
		@"Reception Calibrate using Other Device",
        @"Transmission Calibrate using Calibrated Camera",
        @"Reception Calibrate using Calibrated Screen",
        @"QR Code Roundtrip Calibrate",
        @"Audio Roundtrip Calibrate"
		];
}


@end
