//
//  DocumentView.m
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import "DocumentView.h"

@implementation DocumentView
@synthesize status;
@synthesize values;
@synthesize distribution;
@synthesize document;

- (DocumentView *)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
	if (self) {
		initialValues = NO;
	}
    return self;
}

- (void)viewWillDraw
{
    if (!initialValues) {
        [self updateView];
    }
    [super viewWillDraw];
}

- (void)updateView
{
	if (self.document ) {
        initialValues = YES;
		NSString *measurementType = self.document.measurementType;
		NSString *baseMeasurementID = self.document.baseMeasurementID;
		if (baseMeasurementID) {
			measurementType = [NSString stringWithFormat: @"%@ (based on %@)", measurementType, baseMeasurementID];
		}
		self.status.measurementType = measurementType;
		self.status.inputDevice = self.document.inputDevice;
		self.status.outputDevice = self.document.outputDevice;
		self.status.date = self.document.date;
		self.status.location = self.document.location;
		self.status.description = self.document.description;
		if (self.document.dataStore) {
			self.status.detectCount = [NSString stringWithFormat: @"%d", self.document.dataStore.count];
			self.status.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.document.dataStore.average / 1000.0, document.dataStore.stddev / 1000.0];
			self.status.detectMaxDelay = [NSString stringWithFormat:@"%.3f", self.document.dataStore.max / 1000.0];
			self.status.detectMinDelay = [NSString stringWithFormat:@"%.3f", self.document.dataStore.min / 1000.0];
			self.values.source = self.document.dataStore;
			self.values.maxXformat = @"%.0f";
			self.values.maxYformat = @"%.0f ms";
			self.values.maxYscale = [NSNumber numberWithDouble:0.001];
			self.distribution.source = self.document.dataDistribution;
			//self.distribution.maxXformat = @"%.0f ms";
			//self.distribution.maxXscale = [NSNumber numberWithDouble:0.001];
			//self.distribution.maxYformat = @"%.2f";
		} else {
			self.status.detectCount = @"";
			self.status.detectAverage = @"";
			self.status.detectMaxDelay = @"";
			self.status.detectMinDelay = @"";
		}
	}
    [self.status update:self];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    // This is not very clean.....
    self.status.description = self.status.bDescription.stringValue;
    self.document.description = self.status.description;
    [self.document changed];
}
@end
