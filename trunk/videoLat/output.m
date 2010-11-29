//
//  output.m
//  macMeasurements
//
//  Created by Jack Jansen on 23-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "output.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <CoreServices/CoreServices.h>
#import <sys/time.h>

@implementation Output

- (Output*) init
{
    self = [super init];
    initialized = false;
    terminating = false;
    fp = NULL;
    epoch = 0;
    epoch = [self now];    
       
    return self;
}

- (void) openFile
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

- (void) terminate
{
    if (terminating) return;
    @synchronized(self) {
        terminating = true;
        if (initialized && fp) {
            fclose(fp);
            if (settings.summarize) {
                NSBundle *bundle = [NSBundle mainBundle];
                NSString *cmd_path = [bundle pathForResource:@"pp_summary" ofType:nil];
				NSString *tmpl_path = [bundle pathForResource:@"measurements-summary-graphs-template" ofType:@"numbers"];
                NSString *script_text = [NSString stringWithFormat:
                    @"tell application \"Terminal\"\n"
                     "do script \"python '%@' --template '%@' '%@' && exit\"\n"
                     "end tell\n",
                     cmd_path,
					 tmpl_path,
                     settings.fileName];
                NSAppleScript *script = [[NSAppleScript alloc] initWithSource: script_text];
                NSDictionary *error = nil;;
                NSAppleEventDescriptor *rv = [script executeAndReturnError: &error];
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
    [self terminate];
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
        if (!initialized) [self openFile];
        int64_t now = [self now];
        assert(now > startTime);
        fprintf(fp, "%lld,%s,%s,%s,overhead,%lld\n", now, name, event, data, now-startTime);
    }
}

- (void) output: (const char*)name event: (const char*)event data: (const char*)data
{
    if (terminating) return;
    @synchronized(self) {
        if (!initialized) [self openFile];
        int64_t now = [self now];

        fprintf(fp, "%lld,%s,%s,%s,,\n", now, name, event, data);
    }
}

@end
