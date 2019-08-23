//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "HardwareRunManager.h"
#import "AppDelegate.h"
#import "EventLogger.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <mach/clock.h>
#import <stdlib.h>

@implementation HardwareRunManager

@synthesize outputView;
@dynamic clock;

- (void)dealloc
{
}

- (int) initialPrepareCount { return 100; }
- (int) initialPrepareDelay { return 1000; }

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Hardware Calibrate"];
    [BaseRunManager registerNib: @"HardwareRun" forMeasurementType: @"Hardware Calibrate"];

    [BaseRunManager registerClass: [self class] forMeasurementType: @"Transmission Calibrate using Hardware"];
    [BaseRunManager registerNib: @"ScreenToHardwareRun" forMeasurementType: @"Transmission Calibrate using Hardware"];
    // We should also ensure that the hardware protocol is actually part of the binary
    NSLog(@"HardwareLightProtocol = %@", @protocol(HardwareLightProtocol));
}

- (HardwareRunManager*)init
{
    self = [super init];
	if (self) {
        prepareMaxWaitTime = self.initialPrepareDelay;
	}
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (NSString *)getNewOutputCode
{
    // Called from the redraw routine, should generate a new output code only when needed.
    @synchronized(self) {
        
        // If we are not running we should display a blue-grayish square
        if (!self.running && !self.preparing) {
            return @"undefined";
        }
        if (!self.running && !self.preparing) {
            // Idle, show intermediate value
            self.outputCode = @"undefined";
        } else {
            if ([self.outputCode isEqualToString:@"black"]) {
                self.outputCode = @"white";
            } else {
                self.outputCode = @"black";
            }
        }
        // Set outputCodeTimestamp to 0 to signal we have not reported this outputcode yet
        outputCodeTimestamp = 0;
        return self.outputCode;
    }
}

@end
