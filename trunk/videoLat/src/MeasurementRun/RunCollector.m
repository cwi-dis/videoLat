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
#import "MachineDescription.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <CoreServices/CoreServices.h>
#import <QuartzCore/QuartzCore.h>
#import <sys/time.h>

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
    dataStore = [[MeasurementDataStore alloc] init];
}

- (int) count { return dataStore.count; }
- (double) average { return dataStore.average; }
- (double) stddev { return dataStore.stddev; }
- (void) trim { [dataStore trim]; }

- (void) startCollecting: (NSString*)scenario input: (NSString*)inputId name: (NSString*)inputName output:(NSString*)outputId name: (NSString*)outputName
{
	dataStore.measurementType = scenario;
	MachineDescription *md = [MachineDescription thisMachine];
	dataStore.input.machineID = md.machineID;
    dataStore.input.machine = md.machineName;
	dataStore.input.machineTypeID = md.machineTypeID;
	dataStore.input.device = inputName;
	dataStore.input.deviceID = inputId;
    dataStore.output.machineID = md.machineID;
    dataStore.output.machine = md.machineName;
    dataStore.output.machineTypeID = md.machineTypeID;
	dataStore.output.device = outputName;
	dataStore.output.deviceID = outputId;
}

- (void) startCollecting: (NSString*)scenario
{
	dataStore.measurementType = scenario;
    assert(dataStore.input);
    assert(dataStore.output);

	if (dataStore.input.calibration) {
		dataStore.input.machine = dataStore.input.calibration.input.machine;
		dataStore.input.machineID = dataStore.input.calibration.input.machineID;
		dataStore.input.machineTypeID = dataStore.input.calibration.input.machineTypeID;
		dataStore.input.device = dataStore.input.calibration.input.device;
		dataStore.input.deviceID = dataStore.input.calibration.input.deviceID;
	} else {
		assert(dataStore.input.machine);
		assert(dataStore.input.machineID);
		assert(dataStore.input.machineTypeID);
		assert(dataStore.input.device);
		assert(dataStore.input.deviceID);
	}

	if (dataStore.output.calibration) {
		dataStore.output.machine = dataStore.output.calibration.output.machine;
		dataStore.output.machineID = dataStore.output.calibration.output.machineID;
		dataStore.output.machineTypeID = dataStore.output.calibration.output.machineTypeID;
		dataStore.output.device = dataStore.output.calibration.output.device;
		dataStore.output.deviceID = dataStore.output.calibration.output.deviceID;
	} else {
		assert(dataStore.output.machine);
		assert(dataStore.output.machineID);
		assert(dataStore.output.machineTypeID);
		assert(dataStore.output.device);
		assert(dataStore.output.deviceID);
	}

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

