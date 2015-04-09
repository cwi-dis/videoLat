//
//  DocumentDescriptionView.m
//  videoLat
//
//  Created by Jack Jansen on 12/11/13.
//
//

#import "DocumentDescriptionView.h"
#import "DocumentView.h"

@implementation DocumentDescriptionView
@synthesize bMeasurementType;
@synthesize bDate;
@synthesize bDescription;
@synthesize bDetectCount;
@synthesize bMissCount;
@synthesize bDetectAverage;
@synthesize bDetectMinDelay;
@synthesize bDetectMaxDelay;
@synthesize bCalibration;
@synthesize bCalibrationLabel;
@synthesize bOpenCalibration;

@synthesize vInput;
@synthesize vOutput;

@synthesize modelObject;

#ifdef WITH_UIKIT
// This is rather gross....
#define stringValue text
#endif

- (void)awakeFromNib
{
}

- (void) update: (id)sender
{
	NSString *measurementType = self.modelObject.measurementType;
#if 0
	NSString *inputBaseMeasurementID = self.modelObject.inputBaseMeasurementID;
	NSString *outputBaseMeasurementID = self.modelObject.outputBaseMeasurementID;
	if (inputBaseMeasurementID && outputBaseMeasurementID && ![inputBaseMeasurementID isEqualToString: outputBaseMeasurementID]) {
		measurementType = [NSString stringWithFormat: @"%@ (based on %@ and %@)", measurementType, outputBaseMeasurementID, inputBaseMeasurementID];
	} else if (inputBaseMeasurementID) {
		measurementType = [NSString stringWithFormat: @"%@ (based on %@)", measurementType, inputBaseMeasurementID];
	} else if (outputBaseMeasurementID) {
		measurementType = [NSString stringWithFormat: @"%@ (based on %@)", measurementType, outputBaseMeasurementID];
	}
#endif
	if (bMeasurementType) bMeasurementType.stringValue = measurementType?measurementType:@"";
    if (vInput) [vInput update: self];
    if (vOutput)[vOutput update: self];
	if (bDate) bDate.stringValue = self.modelObject?self.modelObject.date:@"";
	if (bDescription) bDescription.stringValue = self.modelObject?self.modelObject.description:@"";
	if (bDetectCount) bDetectCount.stringValue = self.modelObject?[NSString stringWithFormat: @"%d", self.modelObject.count]:@"";
	if (bMissCount) bMissCount.stringValue = self.modelObject?[NSString stringWithFormat: @"%d", self.modelObject.missCount]:@"";
	if (bDetectAverage) bDetectAverage.stringValue = self.modelObject?[NSString stringWithFormat: @"%.3f ms ± %.3f", self.modelObject.average / 1000.0, self.modelObject.stddev / 1000.0]:@"";
	if (bDetectMinDelay) bDetectMinDelay.stringValue = self.modelObject?[NSString stringWithFormat:@"%.3f", self.modelObject.min / 1000.0]:@"";
	if (bDetectMaxDelay) bDetectMaxDelay.stringValue = self.modelObject?[NSString stringWithFormat:@"%.3f", self.modelObject.max / 1000.0]:@"";
    if (bCalibration) {
        if (![self.modelObject hasSeparateCalibrations]) {
			// We have one (roundtrip) calibration, or no calibration
			MeasurementDataStore *calibration = [self.modelObject inputCalibration];
            [bOpenCalibration setEnabled:YES];
			bOpenCalibration.hidden = NO;
			bCalibration.hidden = NO;
			bCalibrationLabel.hidden = NO;
            bCalibration.stringValue = calibration.descriptiveName;
        } else {
            [bOpenCalibration setEnabled:NO];
			bOpenCalibration.hidden = YES;
			bCalibration.hidden = YES;
			bCalibrationLabel.hidden = YES;
            bCalibration.stringValue = @"";
        }
    }
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    self.modelObject.description = self.bDescription.stringValue;
	// This could be cleaner...
	if ([self.superview respondsToSelector:@selector(modelObject)]) {
		Document *doc = [(DocumentView *)self.superview modelObject];
		[doc changed];
	}
}


@end
