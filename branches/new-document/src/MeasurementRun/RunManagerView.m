//
//  MeasurementTypeView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "RunManagerView.h"
#import "BaseRunManager.h"
#import "MeasurementType.h"
#import "appDelegate.h"

@implementation RunManagerView
@synthesize runManager;

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
}
    
- (IBAction)stopMeasuring: (id)sender
{
    [(BaseRunManager *)self.runManager stop];
    [self.runManager.collector stopCollecting];
    [self.runManager.collector trim];
    self.statusView.detectCount = [NSString stringWithFormat: @"%d (after trimming 5%%)", self.runManager.collector.count];
    self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.runManager.collector.average / 1000.0, self.runManager.collector.stddev / 1000.0];
    [self.statusView update: self];
    NSLog(@"Should do something now with the collector data...");
	appDelegate *d = [[NSApplication sharedApplication] delegate];
	[d openUntitledDocumentWithMeasurement:self.runManager.collector.dataStore];
	[self.window close];
}

@end
