//
//  VideoCalibrationRunManager.h
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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

