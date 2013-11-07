//
//  output.h
//  macMeasurements
//
//  Created by Jack Jansen on 23-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <stdio.h>
#import "SettingsView.h"
#import "protocols.h"

@interface OldCollector : NSObject {
    IBOutlet SettingsView *settings;
    uint64_t epoch;
    FILE *fp;
    bool initialized;
    bool terminating;
}

- (void) _openFile;
- (uint64_t) now;
- (void) terminate;
- (void) output: (const char*)name event: (const char*)event data: (const char*)data start: (uint64_t)startTime;
- (void) output: (const char*)name event: (const char*)event data: (const char*)data;

@end

@interface Collector : OldCollector <DataCollectorProtocol> {
    NSString* lastTransmission;
    uint64_t lastTransmissionTime;
    BOOL lastTransmissionReceived;
    
    double sum;
    double sumSquares;
    double min;
    double max;
    int count;
}

@property(readonly) double min;
@property(readonly) double max;
@property(readonly) double average;
@property(readonly) double stddev;
@property(readonly) int count;

- (void) recordTransmission: (NSString*)data at: (uint64_t)now;
- (void) recordReception: (NSString*)data at: (uint64_t)now;
- (void) _recordDataPoint: (NSString*) data at: (uint64_t)time delay: (uint64_t) delay;
@end
