//  VideoMonoRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "VideoMonoRunManager.h"
#import "EventLogger.h"

// How long we keep a random light level before changing it, when not running or
// prerunning. In microseconds.
#define IDLE_LIGHT_INTERVAL 200000

@implementation VideoMonoRunManager

- (int) initialPrepareCount { return 40; }
- (int) initialPrepareDelay { return 1000; }

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Mono Roundtrip"];
    [BaseRunManager registerNib: @"VideoMonoRun" forMeasurementType: @"Video Mono Roundtrip"];
    // We also register ourselves for camera calibration. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Reception Calibrate using Hardware"];
    [BaseRunManager registerNib: @"HardwareToCameraRun" forMeasurementType: @"Reception Calibrate using Hardware"];
    
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Reception Calibrate using Calibrated Screen"];
    [BaseRunManager registerNib: @"CalibrateCameraFromScreenRun" forMeasurementType: @"Reception Calibrate using Calibrated Screen"];
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Transmission Calibrate using Calibrated Camera"];
    [BaseRunManager registerNib: @"CalibrateScreenFromCameraRun" forMeasurementType: @"Transmission Calibrate using Calibrated Camera"];

#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"Video Mono Roundtrip"];
#endif
}

- (VideoMonoRunManager*)init
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
