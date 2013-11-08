//
//  output.m
//  macMeasurements
//
//  Created by Jack Jansen on 23-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

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

- (void) startCollecting
{
    @synchronized(self) {
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
    [super dealloc];
}

- (uint64_t)now
{
    int64_t now_mach = mach_absolute_time();
    Nanoseconds now_nano = AbsoluteToNanoseconds( *(AbsoluteTime*) &now_mach);
    int64_t now_micro = (*(uint64_t*)&now_nano) / 1000LL;
    return now_micro - epoch;
}

- (void) output: (const char*)name event: (const char*)event data: (const char*)data start: (uint64_t)startTime
{
    if (terminating) return;
    @synchronized(self) {
        if (!initialized) [self startCollecting];
        int64_t now = [self now];
        assert(now >= startTime);
        fprintf(fp, "%lld,%s,%s,%s,overhead,%lld\n", startTime, name, event, data, 0LL);
    }
}

- (void) output: (const char*)name event: (const char*)event data: (const char*)data
{
    if (terminating) return;
    @synchronized(self) {
        if (!initialized) [self startCollecting];
        int64_t now = [self now];
        
        fprintf(fp, "%lld,%s,%s,%s,,\n", now, name, event, data);
    }
}
@end

@implementation Collector

@synthesize min;
@synthesize max;
@synthesize count;

- (double) average
{
    return sum / count;
}

- (double) stddev
{
    double average = sum / count;
    double variance = (sumSquares / count) - (average*average);
    return sqrt(variance);
}

- (Collector*) init
{
    self = [super init];
    lastTransmission = nil;
    sum = 0;
    sumSquares = 0;
    count = 0;
	store = [[NSMutableArray alloc] init];
    return self;
}

- (void) recordTransmission: (NSString*)data at: (uint64_t)now
{
    [lastTransmission release];
    lastTransmission = [data retain];
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
            [self _recordDataPoint: data sent: lastTransmissionTime received: time];
        }
    } else {
        NSLog(@"Collector: received %@, expected %@", data, lastTransmission);
    }
}

- (void) _recordDataPoint: (NSString*) data sent: (uint64_t)sent received: (uint64_t) received
{
	uint64_t delay = received - sent;
    sum += delay;
    sumSquares += (delay * delay);
    if (count == 0 || delay < min) min = delay;
    if (count == 0 || delay > max) max = delay;
    count++;
    NSLog(@"%d %@ %lld-%lld=%lld  µ %f sd %f\n", count, data, received, sent, delay, self.average, self.stddev);
	NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:
		data, @"data",
		[NSNumber numberWithLongLong: received], @"at",
		[NSNumber numberWithLongLong: delay], @"delay",
		nil];
	[store addObject: item];
	
}

- (void)stopCollecting
{
	BOOL success = [NSKeyedArchiver archiveRootObject: store toFile: @"/tmp/videolatdump"];
	[super stopCollecting];
}

@end
