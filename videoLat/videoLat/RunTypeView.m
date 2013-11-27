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

#if 0
- (RunTypeView *)init
{
	self = [super init];
    if (self) {
        wasAwokenFromNib = NO;
	return self;
}
#endif

- (void)awakeFromNib
{
    for (NSString *itemTitle in [bType itemTitles]) {
        if ([BaseRunManager classForMeasurementType: itemTitle] == nil) {
            [[bType itemWithTitle: itemTitle] setEnabled: NO];
        }
    }
    // Try to set same as in previous run
    NSString *oldType = [[NSUserDefaults standardUserDefaults] stringForKey:@"measurementType"];
    if (oldType && [[bType itemWithTitle: oldType] isEnabled])
        [bType selectItemWithTitle: oldType];
	if (self.outputContainerView) {
		for (NSView *subView in [self.outputContainerView subviews])
			[subView removeFromSuperview];
		if (self.outputView)
			[self.outputContainerView addSubview:self.outputView];
	}
	if (self.selectionContainerView) {
		for (NSView *subView in [self.selectionContainerView subviews])
			[subView removeFromSuperview];
		if (self.selectionView)
			[self.selectionContainerView addSubview:self.selectionView];
	}
    if (!wasAwokenFromNib) {
        wasAwokenFromNib = YES;
        [self typeChanged: self];
    }
}

- (IBAction)typeChanged: (id)sender
{
	NSString *typeName = [bType titleOfSelectedItem];
    [[NSUserDefaults standardUserDefaults] setObject:typeName forKey:@"measurementType"];
//	NSArray *typeBaseCalibrations = [MeasurementType measurementNamesForType: typeName];
    // Select corresponding DeviceSelection view
    Class runClass = [BaseRunManager classForMeasurementType: typeName];
	NSString *runClassNib = [BaseRunManager nibForMeasurementType:typeName];
    BOOL ok = YES;
    NSString *errorMsg = @"";
	if (runManager == nil || [runManager class] != runClass) {
        runManager = nil; // Get rid of old runManager.
		NSLog(@"RunTypeView: for %@, selected run class %@ (nib %@)\n", typeName, runClass, runClassNib);
		if (runClassNib) {
			// We have a Nib. Load it, and it will alloc the manager object, we
			// only have to find it (by class)
            NSArray *newObjects;
			if ([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
				ok = [[NSBundle mainBundle] loadNibNamed: runClassNib owner: self topLevelObjects: &newObjects];
			} else {
				newObjects = [[NSMutableArray alloc] initWithCapacity:10];

#if 0
				// For some reason, this doesn't seem to link up the objects correctly?
                NSDictionary *nibDict = @{ NSNibTopLevelObjects : newObjects };
				ok = [[NSBundle mainBundle] loadNibFile:runClassNib externalNameTable:nibDict withZone:nil];
#else
				ok = [NSBundle loadNibNamed:runClassNib owner:self];
#endif
			}
            // Keep the toplevel objects, and search for the runManager by class name (unless it has been set by the NIB already)
            runManagerNibObjects = newObjects;
            if (runManager != nil) {
                // Check that it is the right one...
                if ([runManager class] != runClass) {
                    errorMsg = [NSString stringWithFormat: @"RunTypeView: runManager class is %@, expected %@. Programmer error?\n", [runManager class], runClass];
                    NSLog(@"%@", errorMsg);
                }
            } else {
                // runManager not set by the NIB file. Search for it.
                for (NSObject *obj in runManagerNibObjects) {
                    if ([obj class] == runClass) {
                        if (runManager) {
                            errorMsg = [NSString stringWithFormat: @"RunTypeView: multiple objects of type %@ in NIB file %@. Programmer error?\n", runClass, runClassNib];
                            NSLog(@"%@", errorMsg);
                        }
                        runManager = (BaseRunManager *)obj;
                    }
                }
                if (runManager == nil) {
                    errorMsg = [NSString stringWithFormat: @"RunTypeView: no objects of type %@ in NIB file %@. Programmer error?\n", runClass, runClassNib];
                    NSLog(@"%@", errorMsg);
                }
            }
		} else {
			// We don't have a Nib. Allocate the class instance.
			runManager = [[runClass alloc] init];
			// XXXJACK should we call awakeFromNib or something similar??
		}
	}
    if (!ok || runManager == nil) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error selecting measurement type" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Implementation is missing for %@\n%@", typeName, errorMsg];
        [alert runModal];
        return;
    }
	[runManager selectMeasurementType: typeName];
}

    
- (IBAction)stopMeasuring: (id)sender
{
    self.runManager.running = false;
    [self.collector stopCollecting];
    [self.collector trim];
    self.statusView.detectCount = [NSString stringWithFormat: @"%d (after trimming 5%%)", self.collector.count];
    self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
    [self.statusView update: self];
    [self.document newDocumentComplete: self];
}

@end
