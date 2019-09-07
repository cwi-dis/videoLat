//
//  MeasurementType.m
//  videoLat
//
//  Created by Jack Jansen on 21/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "MeasurementType.h"

static NSMutableDictionary *byName;
static NSMutableDictionary *byTag;

@implementation MeasurementType
@synthesize tag;
@synthesize name;
@synthesize isCalibration;
@synthesize inputOnlyCalibration;
@synthesize outputOnlyCalibration;
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
    MeasurementType *cal_VR = [self addType: @"QR Code Roundtrip Calibrate" tag: 1 isCalibration: YES requires: nil];
    [self addType: @"QR Code Roundtrip" tag: 2 isCalibration: NO requires: cal_VR];
    [self addType: @"Video Mono Roundtrip" tag: 8 isCalibration: NO requires: cal_VR];
    
    MeasurementType *cal_HW = [self addType: @"Hardware Calibrate" tag: 3 isCalibration: YES requires: nil];
    
    MeasurementType *cal_IN = [self addType: @"Reception Calibrate" tag: 4 isCalibration: YES requires: nil];
    cal_IN.inputOnlyCalibration = YES;
    MeasurementType *cal_OUT = [self addType: @"Transmission Calibrate" tag: 5 isCalibration: YES requires: nil];
    cal_OUT.outputOnlyCalibration = YES;
    
    MeasurementType *cal_IN1 = [self addType: @"Reception Calibrate using Hardware" tag: 4 isCalibration: YES requires: cal_HW];
    cal_IN1.inputOnlyCalibration = YES;
    [cal_IN1 setIsSubtypeOf: cal_IN];
    MeasurementType *cal_OUT1 = [self addType: @"Transmission Calibrate using Hardware" tag: 5 isCalibration: YES requires: cal_HW];
    cal_OUT1.outputOnlyCalibration = YES;
    [cal_OUT1 setIsSubtypeOf: cal_OUT];

    MeasurementType *cal_IN2 = [self addType: @"Reception Calibrate using Calibrated Screen" tag: 4 isCalibration: YES requires: cal_OUT];
    cal_IN2.inputOnlyCalibration = YES;
    [cal_IN2 setIsSubtypeOf: cal_IN];
    MeasurementType *cal_OUT2 = [self addType: @"Transmission Calibrate using Calibrated Camera" tag: 5 isCalibration: YES requires: cal_IN];
    cal_OUT2.outputOnlyCalibration = YES;
    [cal_OUT2 setIsSubtypeOf: cal_OUT];

    [self addType: @"QR Code Transmission to Camera Helper" tag: 6 isCalibration: NO requires: cal_OUT];
    [self addType: @"QR Code Reception from Screen Helper" tag: 11 isCalibration: NO requires: cal_IN];
    [self addType: @"QR Code Camera Helper" tag: 7 isCalibration: NO requires: cal_IN];
    [self addType: @"QR Code Screen Helper" tag: 10 isCalibration: NO requires: cal_OUT];

    MeasurementType *cal_IN3 = [self addType: @"Reception Calibrate using Other Device" tag: 4 isCalibration: YES requires: nil];
    cal_IN3.inputOnlyCalibration = YES;
    [cal_IN3 setIsSubtypeOf: cal_IN];
    MeasurementType *cal_OUT3 = [self addType: @"Transmission Calibrate using Other Device" tag: 5 isCalibration: YES requires: nil];
    cal_OUT3.outputOnlyCalibration = YES;
    [cal_OUT3 setIsSubtypeOf: cal_OUT];

    MeasurementType *cal_AR = [self addType: @"Audio Roundtrip Calibrate" tag: 8 isCalibration: YES requires: nil];
    [self addType: @"Audio Roundtrip" tag: 9 isCalibration: NO requires: cal_AR];

}

- (MeasurementType *)initWithType: (NSString *)_name tag: (NSUInteger)_tag isCalibration: (BOOL)_isCalibration requires: (MeasurementType *)_requires
{
    self = [super init];
    if (self) {
        superType = nil;
        name = _name;
        tag = _tag;
        isCalibration = _isCalibration;
        inputOnlyCalibration = NO;
        outputOnlyCalibration = NO;
        requires = _requires;
        measurements = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    return self;
}

- (void) setIsSubtypeOf: (MeasurementType *)_superType
{
    assert(superType == nil);
    assert(self.isCalibration == _superType.isCalibration);
    assert(self.inputOnlyCalibration == _superType.inputOnlyCalibration);
    assert(self.outputOnlyCalibration == _superType.outputOnlyCalibration);
    superType = _superType;
}

- (void)addMeasurement: (MeasurementDataStore *)item
{
	// Create Unique name for measurement
	NSString *itemName = [NSString stringWithFormat: @"%@ to %@", item.output.device, item.input.device];
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
    if (superType) {
        [superType addMeasurement: item];
    }
}

- (MeasurementDataStore *)measurementNamed: (NSString *)itemName
{
	return [measurements objectForKey:itemName];
}

- (NSArray *)measurementNames
{
	return [measurements allKeys];
}

@end
