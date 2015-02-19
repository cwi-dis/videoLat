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
		NSString *measurementType = self.document.dataStore.measurementType;
        NSString *inputBaseMeasurementID = self.document.dataStore.inputBaseMeasurementID;
        NSString *outputBaseMeasurementID = self.document.dataStore.outputBaseMeasurementID;
		if (inputBaseMeasurementID && outputBaseMeasurementID && ![inputBaseMeasurementID isEqualToString: outputBaseMeasurementID]) {
			measurementType = [NSString stringWithFormat: @"%@ (based on %@ and %@)", measurementType, outputBaseMeasurementID, inputBaseMeasurementID];
        } else if (inputBaseMeasurementID) {
            measurementType = [NSString stringWithFormat: @"%@ (based on %@)", measurementType, inputBaseMeasurementID];
        } else if (outputBaseMeasurementID) {
            measurementType = [NSString stringWithFormat: @"%@ (based on %@)", measurementType, outputBaseMeasurementID];
        }
		self.status.measurementType = measurementType;
        self.status.inputMachineTypeID = self.document.dataStore.inputMachineTypeID;
        self.status.inputMachine = self.document.dataStore.inputMachine;
        self.status.inputLocation = self.document.dataStore.inputLocation;
		self.status.inputDevice = self.document.dataStore.inputDevice;
        self.status.outputMachineTypeID = self.document.dataStore.outputMachineTypeID;
        self.status.outputMachine = self.document.dataStore.outputMachine;
        self.status.outputLocation = self.document.dataStore.outputLocation;
		self.status.outputDevice = self.document.dataStore.outputDevice;
		self.status.date = self.document.dataStore.date;
		self.status.description = self.document.dataStore.description;
		if (self.document.dataStore) {
			self.status.detectCount = [NSString stringWithFormat: @"%d", self.document.dataStore.count];
			self.status.missCount = [NSString stringWithFormat: @"%d", self.document.dataStore.missCount];
			self.status.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.document.dataStore.average / 1000.0, document.dataStore.stddev / 1000.0];
			self.status.detectMaxDelay = [NSString stringWithFormat:@"%.3f", self.document.dataStore.max / 1000.0];
			self.status.detectMinDelay = [NSString stringWithFormat:@"%.3f", self.document.dataStore.min / 1000.0];
			self.values.source = self.document.dataStore;
			self.values.maxXformat = @"%.0f";
			self.values.maxYformat = @"%.0f ms";
            self.values.showAverage = YES;
			self.values.maxYscale = [NSNumber numberWithDouble:0.001];
			self.distribution.source = self.document.dataDistribution;
            self.distribution.showNormal = YES;
			self.distribution.maxXformat = @"%.0f ms";
			self.distribution.maxYformat = @"%0.f %%";
            self.distribution.maxYscale = [NSNumber numberWithDouble: 100.0];
			self.distribution.maxXscale = [NSNumber numberWithDouble:0.001];
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
    self.document.dataStore.description = self.status.description;
    [self.document changed];
}
@end
