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

@interface Collector : NSObject <DataCollectorProtocol> {
    IBOutlet SettingsView *settings;
    uint64_t epoch;
    FILE *fp;
    bool initialized;
    bool terminating;
}
- (Collector*) init;
- (void)openFile;
- (uint64_t) now;
- (void) dealloc;
- (void) terminate;
- (void) output: (const char*)name event: (const char*)event data: (const char*)data start: (uint64_t)startTime;
- (void) output: (const char*)name event: (const char*)event data: (const char*)data;

@end
