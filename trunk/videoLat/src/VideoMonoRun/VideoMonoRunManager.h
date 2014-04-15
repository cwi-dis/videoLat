//
//  VideoMonoRunManager.h
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoRunManager.h"

@interface VideoMonoRunManager : VideoRunManager {
    bool currentColorIsWhite;
    // Black/white detection
    int blacklevel;
    int whitelevel;
    int nBWdetections;
    NSRect sensitiveArea;
}

+ (void)initialize;
- (VideoMonoRunManager *)init;

- (CIImage *)newOutputStart;


#if 0
// Monochrome support
- (void)_mono_showNewData;
- (void)_mono_newInputDone: (bool)isWhite;
- (void)_mono_pollInput;
#endif

@end

