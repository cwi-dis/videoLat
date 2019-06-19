///
///  @file VideoCalibrationRunManager.h
///  @brief Implements video roundtrip calibrations.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "VideoRunManager.h"

///
/// Subclass of VideoRunManager with minimal implementation, mainly exists
/// because VideoCalibration runs need to have a different type from normal
/// video runs, so they show up in the meaurement type selection popup menu.
///
@interface VideoCalibrationRunManager : VideoRunManager

+ (void)initialize;
- (VideoCalibrationRunManager *)init;

@end

