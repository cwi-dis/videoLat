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
#import "MeasurementRun.h"


@interface Collector : NSObject <DataCollectorProtocol> {
    NSString* lastTransmission;
    uint64_t lastTransmissionTime;
    BOOL lastTransmissionReceived;
	MeasurementRun *dataStore;
    uint64_t epoch;
}
@property(retain) IBOutlet Document *document;
@property(readonly) double average;
@property(readonly) double stddev;

- (uint64_t) now;
- (void) recordTransmission: (NSString*)data at: (uint64_t)now;
- (void) recordReception: (NSString*)data at: (uint64_t)now;
@end
