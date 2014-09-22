//
//  AudioCalibrationRunManager.h
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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

