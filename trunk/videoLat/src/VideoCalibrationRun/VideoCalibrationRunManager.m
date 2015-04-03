//
//  VideoCalibrationRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "VideoCalibrationRunManager.h"


@implementation VideoCalibrationRunManager

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Roundtrip Calibrate"];
    [BaseRunManager registerNib: @"VideoCalibrationRun" forMeasurementType: @"Video Roundtrip Calibrate"];
#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"Video Roundtrip Calibrate"];
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
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
}

@end
