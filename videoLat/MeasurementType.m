//
//  MeasurementType.m
//  videoLat
//
//  Created by Jack Jansen on 21/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "MeasurementType.h"

static NSMutableDictionary *byName;
static NSMutableDictionary *byTag;

@implementation MeasurementType
@synthesize tag;
@synthesize name;
@synthesize isCalibration;
@synthesize requires;

+ (MeasurementType *)forType: (NSString *)typeName
{
    return [byName objectForKey: typeName];
}

+ (MeasurementType *)forTag: (NSUInteger)tag
{
    return [byTag objectForKey: [NSNumber numberWithInt: (int)tag]];
}

+ (MeasurementType *)addType: (NSString *)typeName tag: (NSUInteger) tag isCalibration: (BOOL)cal requires: (MeasurementType *)req
{
    MeasurementType *item = [[MeasurementType alloc] initWithType:typeName tag:tag isCalibration:cal requires:req];
    [byName setObject: item forKey: typeName];
    [byTag setObject: item forKey:[NSNumber numberWithInt: (int)tag]];
    return item;
}

+ (void)initialize
{
    byName = [[NSMutableDictionary alloc] initWithCapacity: 10];
    byTag = [[NSMutableDictionary alloc] initWithCapacity: 10];
    // NOTE: this list should be identical to the "Measurement Type" popup in NewMeasurement.xib
    MeasurementType *cal_VR = [self addType: @"Video Roundtrip Calibrate" tag: 1 isCalibration: YES requires: nil];
    [self addType: @"Video Roundtrip" tag: 2 isCalibration: NO requires: cal_VR];
     
    MeasurementType *cal_HW = [self addType: @"Hardware Calibrate" tag: 3 isCalibration: YES requires: nil];
    MeasurementType *cal_IN = [self addType: @"Camera Input Calibrate" tag: 4 isCalibration: YES requires: cal_HW];
    MeasurementType *cal_OUT = [self addType: @"Screen Output Calibrate" tag: 5 isCalibration: YES requires: cal_HW];

    [self addType: @"Video Reception" tag: 6 isCalibration: NO requires: cal_IN];
    [self addType: @"Video Transmission" tag: 7 isCalibration: NO requires: cal_OUT];
     
}

- (MeasurementType *)initWithType: (NSString *)_name tag: (NSUInteger)_tag isCalibration: (BOOL)_isCalibration requires: (MeasurementType *)_requires
{
    self = [super init];
    if (self) {
        name = _name;
        tag = _tag;
        isCalibration = _isCalibration;
        requires = _requires;
        measurements = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    return self;
}

- (void)addMeasurement: (MeasurementDataStore *)item
{
	// Create Unique name for measurement
	NSString *itemName = [NSString stringWithFormat: @"%@ to %@", item.outputDevice, item.inputDevice];
	if ([measurements objectForKey:itemName]  != nil) {
		int i = 2;
		for(i=2; ;i++) {
			NSString *itemName2 = [NSString stringWithFormat:@"%@ (%d)", itemName, i];
			if ([measurements objectForKey:itemName2] == nil) {
				itemName = itemName2;
				break;
			}
		}
	}
	[measurements setObject: item forKey: itemName];
}

- (MeasurementDataStore *)measurementNamed: (NSString *)itemName
{
	return [measurements objectForKey:itemName];
}

- (NSArray *)measurementNames
{
	return [measurements allKeys];
}

- (NSArray *)measurementNamesForType: (NSString *)typeName
{
	NSMutableArray *rv = [[NSMutableArray alloc] initWithCapacity:10];
	for (NSString *k in [measurements allKeys]) {
		MeasurementDataStore *v = [measurements objectForKey:k];
		if ([v.measurementType isEqualToString:typeName]) {
			[rv addObject:k];
		}
	}
	return rv;
}

@end
