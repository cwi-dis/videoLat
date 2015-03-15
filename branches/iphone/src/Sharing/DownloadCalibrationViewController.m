//
//  DownloadSelectionView.m
//  videoLat
//
//  Created by Jack Jansen on 08/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "DownloadCalibrationViewController.h"
#import "AppDelegate.h"
#import "MachineDescription.h"
#import "VideoInput.h"
#import "VideoOutputView.h"
#import "CalibrationSharing.h"

@implementation DownloadCalibrationViewController

@synthesize bCalibrations;

- (void) awakeFromNib
{
	[super awakeFromNib];
	[self _listCalibrations];
}

- (void)_listCalibrations
{
	NSString *machineTypeID = [[MachineDescription thisMachine] machineTypeID];
	NSArray *deviceTypeIDs = [VideoInput allDeviceTypeIDs];
	deviceTypeIDs = [deviceTypeIDs arrayByAddingObjectsFromArray:[VideoOutputView allDeviceTypeIDs]];
	NSLog(@"Getting calibrations for %@ and %@", machineTypeID, deviceTypeIDs);
	[[CalibrationSharing sharedUploader] listForMachine: machineTypeID andDevices:deviceTypeIDs delegate:self];
	// XXXX Show progress indicator
}

- (void)availableCalibrations: (NSArray *)_calibrations
{
    calibrations = _calibrations;
    [self _updateCalibrations];
}

- (void)_updateCalibrations
{
    [bCalibrations removeAllItems];
    NSDictionary *cal;
    AppDelegate *ad = (AppDelegate *)[[NSApplication sharedApplication] delegate];
	for (cal in calibrations) {
		NSString *uuid = [cal objectForKey: @"uuid"];
		NSString *calName = [NSString stringWithFormat:@"%@-%@-%@-%@",
							 [cal objectForKey:@"measurementTypeID"],
							 [cal objectForKey:@"machineTypeID"],
							 [cal objectForKey:@"deviceTypeID"],
							 [cal objectForKey:@"uuid"]
							 ];
		[bCalibrations addItemWithTitle:calName];
        if ([ad haveCalibration: uuid])
            [[bCalibrations itemWithTitle:calName] setEnabled: NO];
	}
	if([bCalibrations numberOfItems] == 0) {
		[bCalibrations addItemWithTitle:@"No new calibrations available"];
		[[bCalibrations itemAtIndex: 0] setEnabled: NO];
	}
}


- (IBAction) doDownload: (id)sender
{
    NSLog(@"Should download");
    NSInteger index = [bCalibrations indexOfSelectedItem];
    if (index >= 0) {
        [self _downloadCalibration: [calibrations objectAtIndex:index]];
    }
}

- (void)didDownload: (MeasurementDataStore *)dataStore
{
	NSLog(@"DidDownload: %@", dataStore);
	if (dataStore) {
		AppDelegate *ad = (AppDelegate *)[[NSApplication sharedApplication] delegate];
		[ad performSelectorOnMainThread:@selector(openUntitledDocumentWithMeasurement:) withObject:dataStore waitUntilDone:NO];
	}
}


- (void)_downloadCalibration: (NSDictionary *)calibration
{
	[[CalibrationSharing sharedUploader] downloadAsynchronously:calibration delegate:self];
}

@end
