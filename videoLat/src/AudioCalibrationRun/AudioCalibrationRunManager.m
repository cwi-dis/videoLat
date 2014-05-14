//
//  AudioCalibrationRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "AudioCalibrationRunManager.h"


@implementation AudioCalibrationRunManager

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Audio Roundtrip Calibrate"];
    [BaseRunManager registerNib: @"AudioCalibrationRunManager" forMeasurementType: @"Audio Roundtrip Calibrate"];
}

- (AudioCalibrationRunManager*)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void) awakeFromNib
{
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
}

@end
