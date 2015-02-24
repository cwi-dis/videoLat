//
//  output.m
//  macMeasurements
//
//  Created by Jack Jansen on 23-08-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <AppKit/AppKit.h>
#import <AppKit/NSNibLoading.h>
#import "RunCollector.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <CoreServices/CoreServices.h>
#import <QuartzCore/QuartzCore.h>
#import <sys/time.h>
#import <sys/sysctl.h>
#import <SystemConfiguration/SystemConfiguration.h>

#ifdef CLOCK_IN_COLLECTOR
@implementation RunClock
- (RunClock*) init
{
    self = [super init];
    if (self) {
        epoch = 0;
        epoch = [self now];
    }
    return self;
}

- (uint64_t)now
{
#if 0
    mach_timebase_info_data_t info;
    if (mach_timebase_info(&info) != KERN_SUCCESS) return -1;
    int64_t now_mach = mach_absolute_time();
    int64_t now_nano = now_mach * info.numer / info.denom;
#else
    int64_t now_nano = CVGetCurrentHostTime();
#endif
    int64_t now_micro = now_nano / 1000LL;
    return now_micro - epoch;
}
@end
#endif

@implementation RunCollector
@synthesize dataStore;

- (RunCollector*) init
{
    self = [super init];
    if (self) {
        lastTransmission = nil;
    }
    return self;
}

- (void) dealloc
{
}

- (void) awakeFromNib
{
    dataStore = self.document.dataStore;
}

- (int) count { return dataStore.count; }
- (double) average { return dataStore.average; }
- (double) stddev { return dataStore.stddev; }
- (void) trim { [dataStore trim]; }

- (void) startCollecting: (NSString*)scenario input: (NSString*)inputId name: (NSString*)inputName output:(NSString*)outputId name: (NSString*)outputName
{
	dataStore.measurementType = scenario;
	char hwName_c[100] = "unknown";
	size_t len = sizeof(hwName_c);
	sysctlbyname("hw.model", hwName_c, &len, NULL, 0);
	NSString *hwName = [NSString stringWithUTF8String:hwName_c];
	dataStore.input.machineID = @"00:00:00:00:00:00"; // XXXX
    dataStore.input.machine = (__bridge_transfer NSString *)SCDynamicStoreCopyComputerName(nil, nil);
	dataStore.input.machineTypeID = hwName;
	dataStore.input.device = inputName;
	dataStore.input.deviceID = inputId;
    dataStore.output.machineID = @"00:00:00:00:00:00"; // XXXX
    dataStore.output.machine = (__bridge_transfer NSString *)SCDynamicStoreCopyComputerName(nil, nil);
    dataStore.output.machineTypeID = hwName;
	dataStore.output.device = outputName;
	dataStore.output.deviceID = outputId;
}

- (void) startCollecting: (NSString*)scenario
{
	dataStore.measurementType = scenario;
    assert(dataStore.input);
    assert(dataStore.input.calibration);
    assert(dataStore.output);
    assert(dataStore.output.calibration);
    
    dataStore.input.machine = dataStore.input.calibration.input.machine;
    dataStore.input.machineID = dataStore.input.calibration.input.machineID;
    dataStore.input.machineTypeID = dataStore.input.calibration.input.machineTypeID;
    dataStore.input.device = dataStore.input.calibration.input.device;
    dataStore.input.deviceID = dataStore.input.calibration.input.deviceID;
    
    dataStore.output.machine = dataStore.output.calibration.output.machine;
    dataStore.output.machineID = dataStore.output.calibration.output.machineID;
    dataStore.output.machineTypeID = dataStore.output.calibration.output.machineTypeID;
    dataStore.output.device = dataStore.output.calibration.output.device;
    dataStore.output.deviceID = dataStore.output.calibration.output.deviceID;
}

- (BOOL) recordTransmission: (NSString*)data at: (uint64_t)now
{
    lastTransmission = data;
    lastTransmissionTime = now;
    lastTransmissionReceived = NO;
    return YES;
}

- (BOOL) recordReception: (NSString*)data at: (uint64_t)time
{
    if (lastTransmission == nil) {
        NSLog(@"Collector: received %@ before any transmission", data);
        return NO;
    }
    if ([lastTransmission isEqualToString:data]) {
        if (time < lastTransmissionTime) {
            NSLog(@"Collector: received %@ at %lld, which is earlier than transmit time %lld", data, time, lastTransmissionTime);
            return NO;
        }
        if (!lastTransmissionReceived) {
            lastTransmissionReceived = YES;
            [dataStore addDataPoint: data sent: lastTransmissionTime received: time];
        }
        return YES;
    }
    NSLog(@"Collector: received %@, expected %@, clearing transmission", data, lastTransmission);
	lastTransmission = nil;
	[dataStore addMissingDataPoint: data sent: lastTransmissionTime];
    return NO;
}

- (void)stopCollecting
{
}

@end

