//
//  MeasurementTypeView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "RunTypeView.h"
#import "VideoRunManager.h"
#import "MeasurementType.h"

@implementation RunTypeView
@synthesize bType;
@synthesize runManager;

- (void)awakeFromNib
{
	[runManager setMeasurementTypeName: [bType titleOfSelectedItem]];
}

- (IBAction)typeChanged: (id)sender
{
	NSString *typeName = [sender titleOfSelectedItem];
//	NSArray *typeBaseCalibrations = [MeasurementType measurementNamesForType: typeName];
    // Select corresponding DeviceSelection view
	[runManager setMeasurementTypeName: typeName];
}

@end
