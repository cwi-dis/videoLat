///
///  @file AudioCalibrationRunManager.h
///  @brief Implements audio roundtrip calibrations.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "AudioRunManager.h"

///
/// Subclass of AudioRunManager with minimal implementation, mainly exists
/// because AudioCalibration runs need to have a different type from normal
/// audio runs, so they show up in the measurement type selection popup menu.
///

@interface AudioCalibrationRunManager : AudioRunManager

+ (void)initialize;
- (AudioCalibrationRunManager *)init;

@end

