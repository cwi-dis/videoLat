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

+ (MeasurementType *)withName: (NSString *)name
{
    return [byName objectForKey: name];
}

+ (MeasurementType *)withTag: (NSUInteger)tag
{
    return [byTag objectForKey: [NSNumber numberWithInt: tag]];
}

+ (MeasurementType *))add: (NSString *)name tag: (NSUInteger) tag isCalibration: (BOOL)cal requires: (MeasurementType *)req
{
    MeasurementType *item = [[MeasurementType alloc] initWithName:name tag:tag isCalibration:cal requires:req];
    [byName setObject: item forKey: name];
    [byTag setObject: item forKey:[NSNumber numberWithInt: tag]];
    return item;
}

+ initialize
{
    byName = [[NSMutableDictionary alloc] initWithCapacity: 10];
    byTag = [[NSMutableDictionary alloc] initWithCapacity: 10];
    // NOTE: this list should be identical to the "Measurement Type" popup in NewMeasurement.xib
    [MeasurementType *cal_VR = [self add: @"Video Roundtrip Calibrate" tag: 1 isCalibration: YES requires: nil];
    [self add: @"Video Roundtrip" tag: 2 isCalibration: NO requires: cal_VR];
     
    [MeasurementType *cal_HW = [self add: @"Hardware Calibrate" tag: 3 isCalibration: YES requires: nil];
    [MeasurementType *cal_IN = [self add: @"Camera Input Calibrate" tag: 4 isCalibration: YES requires: cal_HW];
    [MeasurementType *cal_OUT = [self add: @"Screen Output Calibrate" tag: 5 isCalibration: YES requires: cal_HW];

    [self add: @"Video Reception" tag: 6 isCalibration: NO requires: cal_IN];
    [self add: @"Video Transmission" tag: 7 isCalibration: NO requires: cal_OUT];
     
}

- (void)initWithName: (NSString *)name tag: (NSUInteger) tag isCalibration: (BOOL)cal requires: (MeasurementType *)req
{
}

@end
