//
//  MeasurementTypeView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "RunTypeView.h"
#import "BaseRunManager.h"
//#import "VideoRunManager.h"
#import "MeasurementType.h"

@implementation RunTypeView
@synthesize bType;
@synthesize runManager;

- (void)awakeFromNib
{
    for (NSString *itemTitle in [bType itemTitles]) {
        if ([BaseRunManager classForMeasurementType: itemTitle] == nil) {
            [[bType itemWithTitle: itemTitle] setEnabled: NO];
        }
    }
	[runManager selectMeasurementType: [bType titleOfSelectedItem]];
}

- (IBAction)typeChanged: (id)sender
{
	NSString *typeName = [sender titleOfSelectedItem];
//	NSArray *typeBaseCalibrations = [MeasurementType measurementNamesForType: typeName];
    // Select corresponding DeviceSelection view
    Class runClass = [BaseRunManager classForMeasurementType: typeName];
    NSLog(@"Selected run class %@ (but using %@)\n", runClass, [runManager class]);
	[runManager selectMeasurementType: typeName];
}

@end
