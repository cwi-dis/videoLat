//
//  output.h
//  macMeasurements
//
//  Created by Jack Jansen on 23-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <stdio.h>
#import "Document.h"
#import "protocols.h"
#import "MeasurementDataStore.h"


@interface RunCollector : NSObject {
    NSString* lastTransmission;
    uint64_t lastTransmissionTime;
    BOOL lastTransmissionReceived;
	MeasurementDataStore *dataStore;
    uint64_t epoch;
}
@property(retain) IBOutlet Document *document;
@property(readonly) double average;
@property(readonly) double stddev;
@property(readonly) int count;
@property(readonly) MeasurementDataStore *dataStore;
- (uint64_t) now;

- (void) startCollecting: (NSString*)scenario input: (NSString*)inputId name: (NSString*)inputName output:(NSString*)outputId name: (NSString*)outputName;
- (void) stopCollecting;
- (void) trim;

- (void) recordTransmission: (NSString*)data at: (uint64_t)now;
- (void) recordReception: (NSString*)data at: (uint64_t)now;
@end
