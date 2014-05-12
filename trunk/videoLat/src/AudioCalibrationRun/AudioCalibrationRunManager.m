//
//  AudioCalibrationRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
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
