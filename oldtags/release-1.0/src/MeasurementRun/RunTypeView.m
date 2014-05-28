//
//  MeasurementTypeView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "RunTypeView.h"
#import "BaseRunManager.h"
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

- (void) dealloc
{
    if (self.runManager) [(BaseRunManager *)self.runManager stop];
}

- (void) terminate
{
    if (self.runManager) [(BaseRunManager *)self.runManager stop];
}
    
- (void)awakeFromNib
{
    for (NSString *itemTitle in [bType itemTitles]) {
        BOOL exists = [BaseRunManager classForMeasurementType: itemTitle] != nil;
        [[bType itemWithTitle: itemTitle] setEnabled: exists];
    }
    // Try to set same as in previous run
	[bType selectItemAtIndex:-1];
    NSString *oldType = [[NSUserDefaults standardUserDefaults] stringForKey:@"measurementType"];
    if (oldType && [bType itemWithTitle: oldType] && [[bType itemWithTitle: oldType] isEnabled]) {
        [bType selectItemWithTitle: oldType];
	} else {
		[bType selectItemAtIndex: 0];
	}
	if (self.outputContainerView) {
		for (NSView *subView in [self.outputContainerView subviews])
			[subView removeFromSuperview];
		if (self.outputView)
			[self.outputContainerView addSubview:self.outputView];
        self.outputView = nil;
	}
	if (self.selectionContainerView) {
		for (NSView *subView in [self.selectionContainerView subviews])
			[subView removeFromSuperview];
		if (self.selectionView)
			[self.selectionContainerView addSubview:self.selectionView];
        self.selectionView = nil;
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
	if (self.runManager == nil || [self.runManager class] != runClass) {
		if (self.runManager) [(BaseRunManager *)self.runManager stop];
        self.runManager = nil; // Get rid of old runManager.
		if (VL_DEBUG) NSLog(@"RunTypeView: for %@, selected run class %@ (nib %@)\n", typeName, runClass, runClassNib);
		if (runClassNib) {
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
            if (self.runManager != nil) {
                // Check that it is the right one...
                if ([self.runManager class] != runClass) {
                    errorMsg = [NSString stringWithFormat: @"RunTypeView: runManager class is %@, expected %@. Programmer error?\n", [self.runManager class], runClass];
                    NSLog(@"%@", errorMsg);
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"measurementType"];
					abort();
                }
            } else {
                // runManager not set by the NIB file. Search for it.
                for (NSObject *obj in runManagerNibObjects) {
                    if ([obj class] == runClass) {
                        if (self.runManager) {
                            errorMsg = [NSString stringWithFormat: @"RunTypeView: multiple objects of type %@ in NIB file %@. Programmer error?\n", runClass, runClassNib];
                            NSLog(@"%@", errorMsg);
							[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"measurementType"];
							abort();
                        }
                        self.runManager = (BaseRunManager *)obj;
                    }
                }
                if (self.runManager == nil) {
                    errorMsg = [NSString stringWithFormat: @"RunTypeView: no objects of type %@ in NIB file %@. Programmer error?\n", runClass, runClassNib];
                    NSLog(@"%@", errorMsg);
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"measurementType"];
					abort();
                }
            }
            //runManagerNibObjects = nil;
		} else {
			// We don't have a Nib. Allocate the class instance.
			self.runManager = [[runClass alloc] init];
			// XXXJACK should we call awakeFromNib or something similar??
		}
	}
    if (!ok || self.runManager == nil) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error selecting measurement type" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Implementation is missing for %@\n%@", typeName, errorMsg];
        [alert runModal];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"measurementType"];
		return;
    }
	[self.runManager selectMeasurementType: typeName];
}

    
- (IBAction)stopMeasuring: (id)sender
{
    [(BaseRunManager *)self.runManager stop];
    [self.collector stopCollecting];
    [self.collector trim];
    self.statusView.detectCount = [NSString stringWithFormat: @"%d (after trimming 5%%)", self.collector.count];
    self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
    [self.statusView update: self];
    [self.document newDocumentComplete: self];
}

@end
