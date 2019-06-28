//
//  NewMeasurement.m
//  videoLat
//
//  Created by Jack Jansen on 24/02/15.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "NewMeasurementView.h"
#import "BaseRunManager.h"
#import "MachineDescription.h"
#import "VideoInput.h"
#import "VideoOutputView.h"
#import "CalibrationSharing.h"
#import "AppDelegate.h"

@implementation NewMeasurementViewController

@synthesize bType;

- (void) dealloc
{
}


- (void)awakeFromNib
{
	[super awakeFromNib];
    // Test NIB consistency with expectations.
    assert(self.tabView);
    assert(self.bType);
    assert(self.downloadCalibrationViewController);
    
	NSTabViewItem *item = [self.tabView tabViewItemAtIndex: 1];
	assert(item);
	NSView *view = [item view];
	assert(view);
	[self.downloadCalibrationViewController setView: view];
	[self _updateMeasurementTypes];
}

- (void)_updateMeasurementTypes
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

- (IBAction)doMeasurement:(id)sender
{
    NSLog(@"NewMeasurementView.doMeasurement");
    NSString *typeName = [bType titleOfSelectedItem];
    [[NSUserDefaults standardUserDefaults] setObject:typeName forKey:@"measurementType"];

#ifdef DEBUG
    Class runClass = [BaseRunManager classForMeasurementType: typeName];
#endif
    NSString *runClassNib = [BaseRunManager nibForMeasurementType:typeName];
    BOOL ok = YES;
    if (!runClassNib) {
        showWarningAlert([NSString stringWithFormat:@"Implementation missing for measurement type %@", typeName]);
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"measurementType"];
        return;
    }

    // We have a Nib. Load it, and it will alloc the manager object, we
    // only have to find it (by class)
    NSArray *newObjects;
    ok = [[NSBundle mainBundle] loadNibNamed: runClassNib owner: self topLevelObjects: &newObjects];
    if (!ok) {
        showWarningAlert([NSString stringWithFormat:@"NIB missing for measurement type %@", typeName]);
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"measurementType"];
        return;
    }
    
    // Keep the toplevel objects, and search for the runManager by class name (unless it has been set by the NIB already)
    runManagerNibObjects = newObjects;
    assert(self.measurementWindow);
    assert(self.runManagerView);
    assert(self.runManagerView.runManager);
    assert([self.runManagerView.runManager class] == runClass);
    assert(self.runManagerView.selectionView);
    assert(self.runManagerView.outputView);
    assert(self.runManagerView.statusView);
    [self.runManagerView.runManager selectMeasurementType: typeName];
    [[self.runManagerView window] setDelegate: self];
	[[[self view] window] orderOut:self];
}


- (void) windowWillClose: (NSNotification *)notification
{
    NSObject *obj = [notification object];
    if (obj == [self.runManagerView window]) {
        self.runManagerView = nil;
        runManagerNibObjects = nil;
    }
}


@end
