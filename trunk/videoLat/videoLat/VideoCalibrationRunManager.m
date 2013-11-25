//
//  VideoCalibrationRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "VideoCalibrationRunManager.h"


@implementation VideoCalibrationRunManager

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Roundtrip Calibrate"];
    [BaseRunManager registerNib: @"VideoCalibrationRunManager" forMeasurementType: @"Video Roundtrip Calibrate"];
}

- (VideoCalibrationRunManager*)init
{
    self = [super init];
    if (self) {
        _measurementTypeName = @"Video Roundtrip Calibrate";
    }
    return self;
}

@end
