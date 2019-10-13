//  Video3DRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "Video3DRunManager.h"
#import "EventLogger.h"

// How long we keep a random light level before changing it, when not running or
// prerunning. In microseconds.
#define IDLE_LIGHT_INTERVAL 200000

@implementation Video3DRunManager

- (int) initialPrepareCount { return 40; }
- (int) initialPrepareDelay { return 1000; }

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video 3D Roundtrip"];
    [BaseRunManager registerNib: @"Video3DRun" forMeasurementType: @"Video 3D Roundtrip"];

#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"Video 3D Roundtrip"];
#endif
}

- (Video3DRunManager*)init
{
    self = [super init];
    return self;
}

- (NSString *)getNewOutputCode
{
    // Called from the redraw routine, should generate a new output code only when needed.
    @synchronized(self) {
        
        // If we are not running we should display a blue-grayish square
        if (!self.running && !self.preparing) {
            self.outputCode =  @"undefined";
            return self.outputCode;
        }
        if ([self.outputCode isEqualToString:@"black"]) {
            self.outputCode = @"white";
        } else {
            self.outputCode = @"black";
        }
        if (VL_DEBUG) NSLog(@"New output code: %@", self.outputCode);
        // Set outputCodeTimestamp to 0 to signal we have not reported this outputcode yet
        outputCodeTimestamp = 0;
        return self.outputCode;
    }
}
@end
