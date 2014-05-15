//
//  output.h
//  macMeasurements
//
//  Created by Jack Jansen on 23-08-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Cocoa/Cocoa.h>
#import <stdio.h>
#import "Document.h"
#import "protocols.h"
#import "MeasurementDataStore.h"

#undef CLOCK_IN_COLLECTOR
#ifdef CLOCK_IN_COLLECTOR
@interface RunClock : NSObject <ClockProtocol> {
    uint64_t epoch;
}
- (uint64_t) now;
@end
#define BASECLASS RunClock
#else
#define BASECLASS NSObject
#endif

@interface RunCollector : BASECLASS {
    NSString* lastTransmission;
    uint64_t lastTransmissionTime;
    BOOL lastTransmissionReceived;
	MeasurementDataStore *dataStore;
}
@property(weak) IBOutlet Document *document;
@property(readonly) double average;
@property(readonly) double stddev;
@property(readonly) int count;
@property(readonly) MeasurementDataStore *dataStore;

- (void) startCollecting: (NSString*)scenario input: (NSString*)inputId name: (NSString*)inputName output:(NSString*)outputId name: (NSString*)outputName;
- (void) stopCollecting;
- (void) trim;

- (BOOL) recordTransmission: (NSString*)data at: (uint64_t)now;
- (BOOL) recordReception: (NSString*)data at: (uint64_t)now;
@end
