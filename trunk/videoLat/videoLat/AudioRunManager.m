//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "AudioRunManager.h"

@implementation AudioRunManager
+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Audio Calibrate"];
    [BaseRunManager registerNib: @"AudioRunManager" forMeasurementType: @"Audio Calibrate"];
}

- (AudioRunManager*)init
{
    self = [super init];
	if (self) {
	}
    return self;
}

- (void)awakeFromNib
{
    self.statusView = self.measurementMaster.statusView;
    self.collector = self.measurementMaster.collector;
//    if (self.clock == nil) self.clock = self;
    [self restart];
}

- (void)restart
{
	@synchronized(self) {
		if (measurementType == nil) return;
		if (!self.selectionView) {
			// XXXJACK Make sure selectionView is active/visible
		}
		if (measurementType.requires == nil) {
			[self.selectionView.bBase setEnabled:NO];
			[self.selectionView.bRun setEnabled: YES];
		} else {
			NSArray *calibrationNames = measurementType.requires.measurementNames;
            [self.selectionView.bBase removeAllItems];
			[self.selectionView.bBase addItemsWithTitles:calibrationNames];
            if ([self.selectionView.bBase numberOfItems])
                [self.selectionView.bBase selectItemAtIndex:0];
			[self.selectionView.bBase setEnabled:YES];
            
			if ([self.selectionView.bBase selectedItem]) {
				[self.selectionView.bRun setEnabled: YES];
			} else {
				[self.selectionView.bRun setEnabled: NO];
				NSAlert *alert = [NSAlert alertWithMessageText:@"No calibrations available."
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"\"%@\" measurements should be based on a \"%@\" calibration. Please calibrate first.",
                                  measurementType.name,
                                  measurementType.requires.name
                                  ];
				[alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
			}
		}
		self.preRunning = NO;
		self.running = NO;
		[self.selectionView.bRun setEnabled: NO];
		if (self.statusView) {
			[self.statusView.bStop setEnabled: NO];
		}
	}
}

#if 0
- (uint64_t)now
{
    UInt64 machTimestamp = mach_absolute_time();
    Nanoseconds nanoTimestamp = AbsoluteToNanoseconds(*(AbsoluteTime*)&machTimestamp);
    uint64_t timestamp = *(UInt64 *)&nanoTimestamp;
    timestamp = timestamp / 1000;
    return timestamp;
}
#endif

- (void)stop
{
}

- (IBAction)startPreMeasuring: (id)sender
{
}

- (IBAction)stopPreMeasuring: (id)sender
{
}

- (IBAction)startMeasuring: (id)sender
{
}

- (void)triggerNewOutputValue
{
}

- (CIImage *)newOutputStart
{
    return nil;
}

- (void)newOutputDone
{
}

@end
