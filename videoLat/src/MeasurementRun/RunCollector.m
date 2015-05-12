//
//  output.m
//  macMeasurements
//
//  Created by Jack Jansen on 23-08-10.
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "RunCollector.h"
#import "MachineDescription.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <QuartzCore/QuartzCore.h>
#import <sys/time.h>

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
	dataStore.input.os = md.os;
	dataStore.input.videoLatVersion = VIDEOLAT_VERSION_NSSTRING;
	dataStore.input.device = inputName;
	dataStore.input.deviceID = inputId;
    dataStore.output.machineID = md.machineID;
    dataStore.output.machine = md.machineName;
    dataStore.output.machineTypeID = md.machineTypeID;
	dataStore.output.os = md.os;
	dataStore.output.videoLatVersion = VIDEOLAT_VERSION_NSSTRING;
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
		dataStore.input.os = dataStore.input.calibration.input.os;
		dataStore.input.videoLatVersion = dataStore.input.calibration.input.videoLatVersion;
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
		dataStore.output.os = dataStore.input.calibration.output.os;
		dataStore.output.videoLatVersion = dataStore.input.calibration.output.videoLatVersion;
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
#if 0
        if (time < lastTransmissionTime) {
            NSLog(@"Collector: received %@ at %lld, which is %lldus earlier than transmit time %lld", data, time, lastTransmissionTime-time, lastTransmissionTime);
            return NO;
        }
#endif
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

