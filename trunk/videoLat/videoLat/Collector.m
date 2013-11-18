//
//  output.m
//  macMeasurements
//
//  Created by Jack Jansen on 23-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <AppKit/NSNibLoading.h>
#import "Collector.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <CoreServices/CoreServices.h>
#import <sys/time.h>

@implementation OldCollector

- (OldCollector*) init
{
    self = [super init];
    initialized = false;
    terminating = false;
    fp = NULL;
    epoch = 0;
    epoch = [self now];
    
    return self;
}

- (void) startCollecting: (NSString*)scenario input: (NSString*)inputId name: (NSString*)inputName output:(NSString*)outputId name: (NSString*)outputName
{
    @synchronized(self) {
		NSLog(@"Start collecting scenario=%@ input=%@ %@ output=%@ %@\n", scenario, inputId, inputName, outputId, outputName);
        initialized = true;
        
        NSString *fileName = [settings fileName];
        
        fp = fopen([fileName UTF8String], "w");
        if (fp == NULL) {
            NSRunAlertPanel(
                            @"Error",
                            @"Cannot open output file.",
                            nil, nil, nil);
            exit(1);
        }
        
        fprintf(fp, "timestamp,eventClass,eventName,data,extraName,extraData\n");
        struct timeval tv;
        gettimeofday(&tv, NULL);
        long long micro = 1000000LL*tv.tv_sec + tv.tv_usec;
        char buf[100];
        snprintf(buf, sizeof(buf), "%lld", micro);
        [self output:"systemTime" event:"systemTime" data:buf start:0LL];
    }
}

- (void) stopCollecting
{
    if (terminating) return;
    @synchronized(self) {
        terminating = true;
        if (initialized && fp) {
            fclose(fp);
            if (settings.summarize) {
                char *mono_arg = "";
                char *xmit_arg = "";
                char *recv_arg = "";
                if (settings.datatypeBlackWhite) {
                    mono_arg = " --monochrome";
                    if (!settings.recv)
                        recv_arg = " --hwreceive";
                    if (!settings.xmit)
                        xmit_arg = " --hwtransmit";
                }
                NSBundle *bundle = [NSBundle mainBundle];
                NSString *cmd_path = [bundle pathForResource:@"pp_summary" ofType:nil];
				NSString *tmpl_path = [bundle pathForResource:@"measurements-summary-graphs-template" ofType:@"numbers"];
                NSString *script_text = [NSString stringWithFormat:
                                         @"tell application \"Terminal\"\n"
                                         "do script \"python '%@' --template '%@' %s%s%s '%@' && exit\"\n"
                                         "end tell\n",
                                         cmd_path,
                                         tmpl_path,
                                         mono_arg,
                                         xmit_arg,
                                         recv_arg,
                                         settings.fileName];
                NSAppleScript *script = [[NSAppleScript alloc] initWithSource: script_text];
                NSDictionary *error = nil;;
                [script executeAndReturnError: &error];
                if (error) {
                    NSLog(@"AppleScript error: %@", error);
                    NSLog(@"Script: %@", script_text);
                    NSString *msg = [NSString stringWithFormat: @"AppleScript error: %@", error];
                    NSRunAlertPanel(@"Postprocess error", msg, nil, nil, nil);
                    
                }
            }
        }
    }
}

- (void) dealloc
{
    [self stopCollecting];
}

- (uint64_t)now
{
    mach_timebase_info_data_t info;
    if (mach_timebase_info(&info) != KERN_SUCCESS) return -1;
    int64_t now_mach = mach_absolute_time();
    int64_t now_nano = now_mach * info.numer / info.denom;
    int64_t now_micro = now_nano / 1000LL;
    return now_micro - epoch;
}

- (void) output: (const char*)name event: (const char*)event data: (const char*)data start: (uint64_t)startTime
{
    if (terminating) return;
    @synchronized(self) {
        if (!initialized) [self startCollecting: nil input:nil name: nil output:nil name:nil];
        int64_t now = [self now];
        assert(now >= startTime);
        fprintf(fp, "%lld,%s,%s,%s,overhead,%lld\n", startTime, name, event, data, 0LL);
    }
}

- (void) output: (const char*)name event: (const char*)event data: (const char*)data
{
    if (terminating) return;
    @synchronized(self) {
        if (!initialized) [self startCollecting: nil input:nil name: nil output:nil name:nil];
        int64_t now = [self now];
        
        fprintf(fp, "%lld,%s,%s,%s,,\n", now, name, event, data);
    }
}
@end

@implementation Collector

- (Collector*) init
{
    self = [super init];
    lastTransmission = nil;
	dataStore = [[MeasurementRun alloc] init];
    return self;
}

- (int) count { return dataStore.count; }
- (double) average { return dataStore.average; }
- (double) stddev { return dataStore.stddev; }
- (void) trim { [dataStore trim]; }


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
#if 1
    BOOL ok = [NSBundle loadNibNamed:@"VLDocument" owner:dataStore];
    NSLog(@"nibload returned %d\n", (int)ok);
#else
	[NSKeyedArchiver archiveRootObject: dataStore toFile: @"/tmp/videolatdump.videoLat"];
	NSString *csvData = [dataStore asCSVString];
	[csvData writeToFile:@"/tmp/videolatdump.csv" atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
	[super stopCollecting];
#endif
}

@end

