//
//  DocumentDescriptionView.m
//  videoLat
//
//  Created by Jack Jansen on 12/11/13.
//
//

#import "DocumentDescriptionView.h"

@implementation DocumentDescriptionView
@synthesize bMeasurementType;
@synthesize bDate;
@synthesize bDescription;
@synthesize bDetectCount;
@synthesize bMissCount;
@synthesize bDetectAverage;
@synthesize bDetectMinDelay;
@synthesize bDetectMaxDelay;

@synthesize vInput;
@synthesize vOutput;

@synthesize measurementType;
@synthesize date;
@synthesize description;
@synthesize detectCount;
@synthesize missCount;
@synthesize detectAverage;
@synthesize detectMinDelay;
@synthesize detectMaxDelay;

#ifdef WITH_UIKIT
// This is rather gross....
#define stringValue text
#endif

- (void)awakeFromNib
{
}

- (void) update: (id)sender
{
	if (bMeasurementType) bMeasurementType.stringValue = measurementType?measurementType:@"";
    if (vInput) [vInput update: self];
    if (vOutput)[vOutput update: self];
	if (bDate) bDate.stringValue = date?date:@"";
	if (bDescription) bDescription.stringValue = description?description:@"";
	if (bDetectCount) bDetectCount.stringValue = detectCount?detectCount:@"";
	if (bMissCount) bMissCount.stringValue = missCount?missCount:@"";
	if (bDetectAverage) bDetectAverage.stringValue = detectAverage?detectAverage:@"";
	if (bDetectMinDelay) bDetectMinDelay.stringValue = detectMinDelay?detectMinDelay:@"";
	if (bDetectMaxDelay) bDetectMaxDelay.stringValue = detectMaxDelay?detectMaxDelay:@"";
}

@end
