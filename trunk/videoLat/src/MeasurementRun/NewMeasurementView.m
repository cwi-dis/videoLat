//
//  NewMeasurement.m
//  videoLat
//
//  Created by Jack Jansen on 24/02/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "NewMeasurementView.h"
#import "BaseRunManager.h"
#import "MachineDescription.h"
#import "VideoInput.h"
#import "VideoOutputView.h"
#import "CalibrationSharing.h"
#import "appDelegate.h"

@implementation NewMeasurementView

@synthesize bType;

- (void) dealloc
{
}


- (void)awakeFromNib
{
    // Enable only the menu entries for which we have the required calibration
    for (NSString *itemTitle in [bType itemTitles]) {
        if (itemTitle == nil || [itemTitle isEqualToString:@""]) continue;
        BOOL ok = [BaseRunManager classForMeasurementType: itemTitle] != nil;
        if (!ok) continue;
        assert(ok);
        MeasurementType *myType = [MeasurementType forType: itemTitle];
        assert(myType);
        MeasurementType *myCalibration = myType.requires;
        if (myCalibration == nil) {
            ok = YES;
        } else {
            ok = [[myCalibration measurementNames] count] > 0;
        }
        [[bType itemWithTitle: itemTitle] setEnabled: ok];
        if (!ok) {
            NSString *tt = [[bType itemWithTitle: itemTitle] toolTip];
            [[bType itemWithTitle: itemTitle] setToolTip: [NSString stringWithFormat: @"%@\n\nDisabled because it requires a calibration of type %@", tt, myCalibration.name]];
        }
    }
    // Try to set same as in previous run
    [bType selectItemAtIndex:-1];
    NSString *oldType = [[NSUserDefaults standardUserDefaults] stringForKey:@"measurementType"];
    if (oldType && [bType itemWithTitle: oldType] && [[bType itemWithTitle: oldType] isEnabled]) {
        [bType selectItemWithTitle: oldType];
    } else {
        [bType selectItemAtIndex: 0];
    }
}

- (IBAction)measurementTypeOK:(id)sender
{
    NSLog(@"User pressed OK");
    NSString *typeName = [bType titleOfSelectedItem];
    [[NSUserDefaults standardUserDefaults] setObject:typeName forKey:@"measurementType"];

    Class runClass = [BaseRunManager classForMeasurementType: typeName];
    NSString *runClassNib = [BaseRunManager nibForMeasurementType:typeName];
    BOOL ok = YES;
    if (!runClassNib) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error selecting measurement type" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Implementation is missing for %@\n", typeName];
        [alert runModal];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"measurementType"];
        return;
    }

    // We have a Nib. Load it, and it will alloc the manager object, we
    // only have to find it (by class)
    NSArray *newObjects;
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
    if ([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
        ok = [[NSBundle mainBundle] loadNibNamed: runClassNib owner: self topLevelObjects: &newObjects];
    } else
#endif
    {
        newObjects = [[NSMutableArray alloc] initWithCapacity:10];
        
        ok = [NSBundle loadNibNamed:runClassNib owner:self];
    }
    if (!ok) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error selecting measurement type" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"NIB is missing for %@\n", typeName];
        [alert runModal];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"measurementType"];
        return;
    }
    
    // Keep the toplevel objects, and search for the runManager by class name (unless it has been set by the NIB already)
    runManagerNibObjects = newObjects;
    assert(self.runManagerView);
    assert(self.runManagerView.runManager);
    assert([self.runManagerView.runManager class] == runClass);
    [self.runManagerView.runManager selectMeasurementType: typeName];
    NSLog(@"Should hide NewMeasurementView window....");
    [[self.runManagerView window] setDelegate: self];
	[self.window orderOut:self];
}

- (IBAction)measurementTypeDownload:(id)sender
{
    NSLog(@"User pressed Download");
	NSString *machineTypeID = [[MachineDescription thisMachine] machineTypeID];
	NSArray *deviceTypeIDs = [VideoInput allDeviceTypeIDs];
	deviceTypeIDs = [deviceTypeIDs arrayByAddingObjectsFromArray:[VideoOutputView allDeviceTypeIDs]];
	NSLog(@"Should get calibrations for %@ and %@", machineTypeID, deviceTypeIDs);
	[[CalibrationSharing sharedUploader] listForMachine: machineTypeID andDevices:deviceTypeIDs delegate:self];
	// XXXX Show progress indicator
}

- (void)availableCalibrations: (NSArray *)calibrations
{
	NSLog(@"calibrations: %@", calibrations);
	// XXXX Hide progress indicator
	if (calibrations && [calibrations count] > 0) {
		// xxx load NIB file
}

- (void) windowWillClose: (NSNotification *)notification
{
    NSObject *obj = [notification object];
    if (obj == [self.runManagerView window]) {
        self.runManagerView = nil;
        runManagerNibObjects = nil;
        [self.window close];
    }
}


@end
