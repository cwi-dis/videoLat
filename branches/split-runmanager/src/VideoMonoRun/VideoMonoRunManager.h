//
//  VideoMonoRunManager.h
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>
#import "VideoRunManager.h"

///
/// Subclass of VideoRunManager that uses 100% black/white pictures to measure delay.
/// Overrides a minimal number of methods to handle black/white, a lot of the other
/// changes are made through the NIB file. Compatible with HardwareRunManager.
///
@interface VideoMonoRunManager : VideoRunManager {
    bool currentColorIsWhite;   //!< Internal: true when we are displaying white
    // Black/white detection
    int blacklevel;             //!< Internal: darkest color seen during prerun
    int whitelevel;             //!< Internal: lightest color seen during prerun
    NSRect sensitiveArea;       //!< Internal: where we look for black/white in the input signal.
}

+ (void)initialize;
- (VideoMonoRunManager *)init;

- (CIImage *)newOutputStart;

@end

