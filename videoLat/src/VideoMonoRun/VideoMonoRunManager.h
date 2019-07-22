///
///  @file VideoMonoRunManager.h
///  @brief Implements video black/white measurements.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "VideoRunManager.h"
#import "LevelStatusView.h"
#import "compat.h"

///
/// Subclass of VideoRunManager that uses 100% black/white pictures to measure delay.
/// Overrides a minimal number of methods to handle black/white, a lot of the other
/// changes are made through the NIB file. Compatible with HardwareRunManager.
///
@interface VideoMonoRunManager : VideoRunManager {
    // Black/white detection
}

+ (void)initialize;
- (VideoMonoRunManager *)init;
- (CIImage *)newOutputStart;
@end

