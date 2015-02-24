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
@synthesize bInputMachineTypeID;
@synthesize bInputMachine;
@synthesize bInputLocation;
@synthesize bInputDevice;
@synthesize bOutputMachineTypeID;
@synthesize bOutputMachine;
@synthesize bOutputLocation;
@synthesize bOutputDevice;
@synthesize bDate;
@synthesize bDescription;
@synthesize bDetectCount;
@synthesize bMissCount;
@synthesize bDetectAverage;
@synthesize bDetectMinDelay;
@synthesize bDetectMaxDelay;

@synthesize measurementType;
@synthesize inputMachineTypeID;
@synthesize inputMachine;
@synthesize inputLocation;
@synthesize inputDevice;
@synthesize outputMachineTypeID;
@synthesize outputMachine;
@synthesize outputLocation;
@synthesize outputDevice;
@synthesize date;
@synthesize description;
@synthesize detectCount;
@synthesize missCount;
@synthesize detectAverage;
@synthesize detectMinDelay;
@synthesize detectMaxDelay;

- (void)awakeFromNib
{
}

- (void) update: (id)sender
{
	if (bMeasurementType) bMeasurementType.stringValue = measurementType?measurementType:@"";
    if (bInputMachineTypeID) bInputMachineTypeID.stringValue = inputMachine?inputMachineTypeID:@"";
    if (bInputMachine) bInputMachine.stringValue = inputMachine?inputMachine:@"";
    if (bInputLocation) bInputLocation.stringValue = inputLocation?inputLocation:@"";
	if (bInputDevice) bInputDevice.stringValue = inputDevice?inputDevice:@"";
    if (bOutputMachineTypeID) bOutputMachineTypeID.stringValue = outputMachine?outputMachineTypeID:@"";
    if (bOutputMachine) bOutputMachine.stringValue = outputMachine?outputMachine:@"";
    if (bOutputLocation) bOutputLocation.stringValue = outputLocation?outputLocation:@"";
	if (bOutputDevice) bOutputDevice.stringValue = outputDevice?outputDevice:@"";
	if (bDate) bDate.stringValue = date?date:@"";
	if (bDescription) bDescription.stringValue = description?description:@"";
	if (bDetectCount) bDetectCount.stringValue = detectCount?detectCount:@"";
	if (bMissCount) bMissCount.stringValue = detectCount?missCount:@"";
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
