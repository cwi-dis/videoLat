//
//  VideoCalibrationRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "VideoCalibrationRunManager.h"


@implementation VideoCalibrationRunManager

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"QR Code Roundtrip Calibrate"];
    [BaseRunManager registerNib: @"VideoCalibrationRun" forMeasurementType: @"QR Code Roundtrip Calibrate"];
#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"QR Code Roundtrip Calibrate"];
#endif
}

- (VideoCalibrationRunManager*)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

@end
