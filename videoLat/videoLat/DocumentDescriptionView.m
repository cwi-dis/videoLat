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
@synthesize bMachine;
@synthesize bInputDevice;
@synthesize bOutputDevice;
@synthesize bDate;
@synthesize bLocation;
@synthesize bDescription;
@synthesize bDetectCount;
@synthesize bDetectAverage;
@synthesize bDetectMinDelay;
@synthesize bDetectMaxDelay;

@synthesize measurementType;
@synthesize machine;
@synthesize inputDevice;
@synthesize outputDevice;
@synthesize date;
@synthesize location;
@synthesize description;
@synthesize detectCount;
@synthesize detectAverage;
@synthesize detectMinDelay;
@synthesize detectMaxDelay;

- (void)awakeFromNib
{
}

- (void) update: (id)sender
{
	if (bMeasurementType) bMeasurementType.stringValue = measurementType?measurementType:@"";
	if (bMachine) bMachine.stringValue = machine?machine:@"";
	if (bInputDevice) bInputDevice.stringValue = inputDevice?inputDevice:@"";
	if (bOutputDevice) bOutputDevice.stringValue = outputDevice?outputDevice:@"";
	if (bDate) bDate.stringValue = date?date:@"";
	if (bLocation) bLocation.stringValue = location?location:@"";
	if (bDescription) bDescription.stringValue = description?description:@"";
	if (bDetectCount) bDetectCount.stringValue = detectCount?detectCount:@"";
	if (bDetectAverage) bDetectAverage.stringValue = detectAverage?detectAverage:@"";
	if (bDetectMinDelay) bDetectMinDelay.stringValue = detectMinDelay?detectMinDelay:@"";
	if (bDetectMaxDelay) bDetectMaxDelay.stringValue = detectMaxDelay?detectMaxDelay:@"";

#if 0
    if (NSIsEmptyRect(finderRect)) {
        [bFinderRect setStringValue: @"No QR code found yet"];
    } else {
        NSString * loc = [NSString stringWithFormat: @"pos %d,%d size %d,%d", 
            (int)finderRect.origin.x,
            (int)finderRect.origin.y,
            (int)finderRect.size.width,
            (int)finderRect.size.height];
        [bFinderRect setStringValue: loc];
    }
    [bBWstatus setStringValue: bwString];
#endif
}

@end
