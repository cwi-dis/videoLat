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
#import "MeasurementRun.h"

@interface OldCollector : NSObject {
    IBOutlet SettingsView *settings;
    uint64_t epoch;
    FILE *fp;
    bool initialized;
    bool terminating;
}

- (void) startCollecting: (NSString*)scenario input: (NSString*)inputId name: (NSString*)inputName output:(NSString*)outputId name: (NSString*)outputName;
- (uint64_t) now;
- (void) stopCollecting;
- (void) output: (const char*)name event: (const char*)event data: (const char*)data start: (uint64_t)startTime;
- (void) output: (const char*)name event: (const char*)event data: (const char*)data;

@end

@interface Collector : OldCollector <DataCollectorProtocol> {
    NSString* lastTransmission;
    uint64_t lastTransmissionTime;
    BOOL lastTransmissionReceived;
	MeasurementRun *dataStore;
}

- (void) recordTransmission: (NSString*)data at: (uint64_t)now;
- (void) recordReception: (NSString*)data at: (uint64_t)now;
@end
