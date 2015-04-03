//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>
#import "AudioRunManager.h"
#import "MachineDescription.h"

@implementation AudioRunManager

- (int) initialPrerunCount { return 10; }
- (int) initialPrerunDelay { return 1000000; }

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Audio Roundtrip"];
    [BaseRunManager registerNib: @"AudioRun" forMeasurementType: @"Audio Roundtrip"];
#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"AudioInputSelectionView" forMeasurementType: @"Audio Roundtrip"];
#endif
}


- (void)dealloc
{
    // Deallocate the capturer first
    self.capturer = nil;
	self.clock = nil;
}


- (AudioRunManager*)init
{
    self = [super init];
	if (self) {
		outputStartTime = 0;
		outputActive = NO;
		foundCurrentSample = NO;
		triggerOutputWhenDone = NO;
		maxDelay = 0;
		prerunMoreNeeded = 0;
	}
    return self;
}

- (void)awakeFromNib
{
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
//    if (self.clock == nil) self.clock = self;
    [self restart];
}

#if 0
- (uint64_t)now
{
    UInt64 machTimestamp = mach_absolute_time();
    Nanoseconds nanoTimestamp = AbsoluteToNanoseconds(*(AbsoluteTime*)&machTimestamp);
    uint64_t timestamp = *(UInt64 *)&nanoTimestamp;
    timestamp = timestamp / 1000;
    return timestamp;
}
#endif

- (void)stop
{
	if (self.capturer) [self.capturer stop];
	if (self.outputView) [self.outputView stop];
	self.capturer = nil;
	self.outputView = nil;
}

- (void)triggerNewOutputValue
{
	if (outputActive) {
		// We cannot start a new output when one is active. Remember for later
		triggerOutputWhenDone = YES;
		return;
	}
	triggerOutputWhenDone = NO;
	[self.outputView performSelectorOnMainThread:@selector(showNewData) withObject:nil waitUntilDone:NO ];
}

- (CIImage *)newOutputStart
{
	assert(!outputActive);
	outputActive = YES;
	foundCurrentSample = NO;
    if ((self.running || self.preRunning)) {
        outputStartTime = [self.clock now];
		if (VL_DEBUG) NSLog(@"AudioRun.newOutputStart at %lld", outputStartTime);
		if (self.running) {
			[self.collector recordTransmission: @"audio" at: outputStartTime];
        }
        
    }
    return nil;
}

- (void)newOutputDone
{
    if (VL_DEBUG) NSLog(@"AudioRun.newOutputDone at %lld", [self.clock now]);
	assert(outputActive);
	outputActive = NO;
	if (triggerOutputWhenDone)
		[self triggerNewOutputValue];
}

- (void) newInputDone: (void*)buffer size: (int)size channels: (int)channels at: (uint64_t)timestamp
{
    @synchronized(self) {
		// See whether we detect the pattern we are looking for, and report to user.
        BOOL foundSample = [self.processor feedData:buffer size:size channels:channels bitsPerChannel: 16 at:timestamp];
#ifdef WITH_UIKIT
		dispatch_async(dispatch_get_main_queue(), ^{
			self.bDetection.on = foundSample;
		});
#else
		[self.bDetection setState: (foundSample? NSOnState : NSOffState)];
#endif

		// If we're not running or prerunning we're done.
		if (!self.running && !self.preRunning)
			return;

		// If we have already reported a match there's nothing more to do
		if (foundCurrentSample)
			return;
			
		// Process whether we found a sample (or not)
        if (foundSample) {
			if (VL_DEBUG) NSLog(@"newInputDone (%lld) at %lld", timestamp, [self.clock now]);
			foundCurrentSample = YES;
            if (self.running) {
                [self.collector recordReception: @"audio" at: [self.processor lastMatchTimestamp]];
            } else if (self.preRunning) {
                [self _prerunRecordReception: self.outputCompanion.outputCode];
            }
            [self.outputCompanion triggerNewOutputValue];
        } else {
			// Nothing found. See whether we are still expecting something
			if ([self.clock now] - outputStartTime > maxDelay) {
				// No we are not. Admit failure, and do another sample.
				if (self.preRunning) {
					[self _prerunRecordNoReception];
				} else {
					[self.collector recordReception: @"noaudio" at: [self.clock now]];
				}
				[self.outputCompanion triggerNewOutputValue];
			}
        }

		// Update status display, if we are running
		if (self.running) {
			self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
			self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
            [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
		}
    }
}

- (void) _prerunRecordNoReception
{
	assert(handlesInput);
    if (VL_DEBUG) NSLog(@"Prerun no reception\n");
    assert(self.preRunning);
	// No data found within alotted time. Double the time, reset the count, change mirroring
	if (1 || VL_DEBUG) NSLog(@"outputStartTime=%llu, maxDelay=%llu\n", outputStartTime, maxDelay);
	maxDelay = maxDelay + (maxDelay / 4);
	prerunMoreNeeded = self.initialPrerunCount;
	self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prerunMoreNeeded];
	self.statusView.detectAverage = @"";
	[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
}

- (void) _prerunRecordReception: (NSString *)code
{
    if (1 || VL_DEBUG) NSLog(@"prerun reception %@\n", code);
    assert(self.preRunning);
    if (self.preRunning) {
	
        prerunMoreNeeded -= 1; // And we need one less
		
        self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prerunMoreNeeded];
		self.statusView.detectAverage = @"";
        [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
        if (1 || VL_DEBUG) NSLog(@"preRunMoreMeeded=%d\n", prerunMoreNeeded);
		
        if (prerunMoreNeeded == 0) {
            self.statusView.detectCount = @"";
			self.statusView.detectAverage = @"";
            [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
            [self performSelectorOnMainThread: @selector(stopPreMeasuring:) withObject: self waitUntilDone: NO];
        }
    }
}
@end