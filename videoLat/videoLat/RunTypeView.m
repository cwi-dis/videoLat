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

- (RunTypeView *)init
{
	self = [super init];
	return self;
}

- (void)awakeFromNib
{
    for (NSString *itemTitle in [bType itemTitles]) {
        if ([BaseRunManager classForMeasurementType: itemTitle] == nil) {
            [[bType itemWithTitle: itemTitle] setEnabled: NO];
        }
    }
	NSLog(@"outputContainerView=%@\n", self.outputContainerView);
	NSLog(@"selectionContainerView=%@\n", self.selectionContainerView);
	NSLog(@"outputView=%@\n", self.outputView);
	NSLog(@"selectionView=%@\n", self.selectionView);
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
}

- (void)viewDidMoveToSuperview:(NSView *)newSuperview
{
	[self typeChanged: self];
}

- (IBAction)typeChanged: (id)sender
{
	NSString *typeName = [bType titleOfSelectedItem];
//	NSArray *typeBaseCalibrations = [MeasurementType measurementNamesForType: typeName];
    // Select corresponding DeviceSelection view
    Class runClass = [BaseRunManager classForMeasurementType: typeName];
	NSString *runClassNib = [BaseRunManager nibForMeasurementType:typeName];
    NSLog(@"RunTypeView: for %@, selected run class %@ (nib %@)\n", typeName, runClass, runClassNib);
	if (runClassNib) {
		// We have a Nib. Load it, and it will alloc the manager object, we
		// only have to find it (by class)
		if ([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
			NSArray *newObjects;
			BOOL ok = [[NSBundle mainBundle] loadNibNamed: runClassNib owner: self topLevelObjects: &newObjects];
			runManagerNibObjects = newObjects;
		} else {
			BOOL ok = [NSBundle loadNibNamed:runClassNib owner:self];
		}
	} else {
		// We don't have a Nib. Allocate the class instance.
		runManager = [[runClass alloc] init];
		// XXXJACK should we call awakeFromNib or something similar??
	}
	[runManager selectMeasurementType: typeName];
}

@end
