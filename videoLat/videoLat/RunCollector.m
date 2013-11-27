//
//  output.m
//  macMeasurements
//
//  Created by Jack Jansen on 23-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <AppKit/NSNibLoading.h>
#import "RunCollector.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <CoreServices/CoreServices.h>
#import <sys/time.h>

@implementation RunCollector
@synthesize dataStore;

- (RunCollector*) init
{
    self = [super init];
    if (self) {
        lastTransmission = nil;
        epoch = 0;
        epoch = [self now];
    }
    return self;
}

- (void) awakeFromNib
{
    dataStore = self.document.dataStore;
}

- (int) count { return dataStore.count; }
- (double) average { return dataStore.average; }
- (double) stddev { return dataStore.stddev; }
- (void) trim { [dataStore trim]; }

- (uint64_t)now
{
    mach_timebase_info_data_t info;
    if (mach_timebase_info(&info) != KERN_SUCCESS) return -1;
    int64_t now_mach = mach_absolute_time();
    int64_t now_nano = now_mach * info.numer / info.denom;
    int64_t now_micro = now_nano / 1000LL;
    return now_micro - epoch;
}

- (void) startCollecting: (NSString*)scenario input: (NSString*)inputId name: (NSString*)inputName output:(NSString*)outputId name: (NSString*)outputName
{
	dataStore.measurementType = scenario;
	dataStore.inputDevice = inputName;
	dataStore.inputDeviceID = inputId;
	dataStore.outputDevice = outputName;
	dataStore.outputDeviceID = outputId;
}

- (void) recordTransmission: (NSString*)data at: (uint64_t)now
{
    lastTransmission = data;
    lastTransmissionTime = now;
    lastTransmissionReceived = NO;
}

- (void) recordReception: (NSString*)data at: (uint64_t)time
{
    if (lastTransmission == nil) {
        NSLog(@"Collector: received %@ before any transmission", data);
        return;
    }
    if ([lastTransmission isEqualToString:data]) {
        if (time < lastTransmissionTime) {
            NSLog(@"Collector: received %@ at %lld, which is earlier than transmit time %lld", data, time, lastTransmissionTime);
            return;
        }
        if (!lastTransmissionReceived) {
            lastTransmissionReceived = YES;
            [dataStore addDataPoint: data sent: lastTransmissionTime received: time];
        }
    } else {
        NSLog(@"Collector: received %@, expected %@", data, lastTransmission);
    }
}

- (void)stopCollecting
{
}

@end

