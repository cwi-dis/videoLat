//
//  DocumentView.m
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import "DocumentView.h"
#import "AppDelegate.h"

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
            outputBaseMeasurementID = inputBaseMeasurementID;
        } else if (outputBaseMeasurementID) {
            measurementType = [NSString stringWithFormat: @"%@ (based on %@)", measurementType, outputBaseMeasurementID];
            inputBaseMeasurementID = outputBaseMeasurementID;
        }
		self.status.measurementType = measurementType;
        self.status.inputMachineTypeID = self.document.dataStore.input.machineTypeID;
        self.status.inputMachine = self.document.dataStore.input.machine;
        self.status.inputLocation = self.document.dataStore.input.location;
        self.status.inputDevice = self.document.dataStore.input.device;
        self.status.inputCalibration= inputBaseMeasurementID;
        self.status.outputMachineTypeID = self.document.dataStore.output.machineTypeID;
        self.status.outputMachine = self.document.dataStore.output.machine;
        self.status.outputLocation = self.document.dataStore.output.location;
		self.status.outputDevice = self.document.dataStore.output.device;
        self.status.outputCalibration= outputBaseMeasurementID;
		self.status.date = self.document.dataStore.date;
		self.status.description = self.document.dataStore.description;
		if (self.document.dataStore) {
			self.status.detectCount = [NSString stringWithFormat: @"%d", self.document.dataStore.count];
			self.status.missCount = [NSString stringWithFormat: @"%d", self.document.dataStore.missCount];
			self.status.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.document.dataStore.average / 1000.0, document.dataStore.stddev / 1000.0];
			self.status.detectMaxDelay = [NSString stringWithFormat:@"%.3f", self.document.dataStore.max / 1000.0];
			self.status.detectMinDelay = [NSString stringWithFormat:@"%.3f", self.document.dataStore.min / 1000.0];
			self.values.source = self.document.dataStore;
			self.values.xLabelFormat = @"%.0f";
			self.values.yLabelFormat = @"%.0f ms";
            self.values.showAverage = YES;
			self.values.yLabelScaleFactor = [NSNumber numberWithDouble:0.001];
			self.distribution.source = self.document.dataDistribution;
            self.distribution.showNormal = YES;
			self.distribution.xLabelFormat = @"%.0f ms";
			self.distribution.yLabelFormat = @"%0.f %%";
            self.distribution.yLabelScaleFactor = [NSNumber numberWithDouble: 100.0];
			self.distribution.xLabelScaleFactor = [NSNumber numberWithDouble:0.001];
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

- (IBAction)openInputCalibration:(id)sender
{
    AppDelegate *d = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    MeasurementDataStore *s = self.document.dataStore.inputCalibration;
    if (d && s) {
        [d openUntitledDocumentWithMeasurement:s];
    }
}

- (IBAction)openOutputCalibration:(id)sender
{
    AppDelegate *d = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    MeasurementDataStore *s = self.document.dataStore.outputCalibration;
    if (d && s) {
        [d openUntitledDocumentWithMeasurement:s];
    }
}
@end
