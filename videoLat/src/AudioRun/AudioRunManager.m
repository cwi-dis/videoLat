//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>
#import "AudioRunManager.h"
#import "MachineDescription.h"
#import "EventLogger.h"

@implementation AudioRunManager
@synthesize outputView;
@synthesize selectionView;
@dynamic clock;

- (int) initialPrepareCount { return 10; }
- (int) initialPrepareDelay { return 1000000; }

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
		outputCodeTimestamp = 0;
		outputDeviceBusy = NO;
		foundCurrentSample = NO;
		triggerOutputWhenDone = NO;
		prepareMaxWaitTime = 0;
		prepareMoreNeeded = 0;
	}
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    assert(self.outputView);
    assert(self.clock);
    assert(self.processor);
    assert(self.bDetection);
#ifdef WITH_APPKIT
    assert(self.selectionView);
#endif
//    if (self.clock == nil) self.clock = self;
    [self restart];
}

- (void)stop
{
	if (self.capturer) [self.capturer stop];
	if (self.outputView) [self.outputView stop];
	self.capturer = nil;
	self.outputView = nil;
}

- (void)triggerNewOutputValue
{
	if (outputDeviceBusy) {
		// We cannot start a new output when one is active. Remember for later
		triggerOutputWhenDone = YES;
		return;
	}
	triggerOutputWhenDone = NO;
	[self.outputView performSelectorOnMainThread:@selector(showNewData) withObject:nil waitUntilDone:NO ];
}

- (CIImage *)getNewOutputImage
{
    assert(!outputDeviceBusy);
    outputDeviceBusy = YES;
    foundCurrentSample = NO;
    if ((self.running || self.preparing)) {
        outputCodeTimestamp = [self.clock now];
        if (VL_DEBUG) NSLog(@"AudioRun.getNewOutputImage at %lld", outputCodeTimestamp);
        if (self.running) {
            [self.collector recordTransmission: @"audio" at: outputCodeTimestamp];
			VL_LOG_EVENT(@"transmission", outputCodeTimestamp, @"audio");

        }
        
    }
    return nil;
}

- (void)newOutputStartAt: (uint64_t) startTime
{
    assert(!outputDeviceBusy);
    outputDeviceBusy = YES;
    foundCurrentSample = NO;
    if ((self.running || self.preparing)) {
        outputCodeTimestamp = startTime;
        if (VL_DEBUG) NSLog(@"AudioRun.getNewOutputImage at %lld clock=%lld", outputCodeTimestamp, [self.clock now]);
        if (self.running) {
            [self.collector recordTransmission: @"audio" at: outputCodeTimestamp];
			VL_LOG_EVENT(@"transmission", outputCodeTimestamp, @"audio");
        }
        
    }
}

- (void)newOutputDone
{
    if (VL_DEBUG) NSLog(@"AudioRun.newOutputDone at %lld", [self.clock now]);
	assert(outputDeviceBusy);
	outputDeviceBusy = NO;
	if (triggerOutputWhenDone)
		[self triggerNewOutputValue];
}

- (void) newInputDone: (void*)buffer size: (int)size channels: (int)channels at: (uint64_t)timestamp duration: (uint64_t)duration
{
    @synchronized(self) {
		// See whether we detect the pattern we are looking for, and report to user.
		if (VL_DEBUG) NSLog(@"Got %d samples %lldµS", size/(channels*2), duration);
        BOOL foundSample = [self.processor feedData:buffer size:size channels:channels bitsPerChannel: 16 at:timestamp duration: duration];
#ifdef WITH_UIKIT
		dispatch_async(dispatch_get_main_queue(), ^{
			self.bDetection.on = foundSample;
		});
#else
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.bDetection setState: (foundSample? NSOnState : NSOffState)];
        });
#endif

		// If we're not running or prerunning we're done.
		if (!self.running && !self.preparing)
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
				VL_LOG_EVENT(@"reception", [self.processor lastMatchTimestamp], @"audio");
            } else if (self.preparing) {
                [self prepareReceivedValidCode: self.outputCompanion.outputCode];
            }
            [self.outputCompanion triggerNewOutputValueAfterDelay];
        } else {
			// Nothing found. See whether we are still expecting something
			if ([self.clock now] > outputCodeTimestamp + prepareMaxWaitTime) {
				// No we are not. Admit failure, and do another sample.
				if (self.preparing) {
					[self prepareReceivedNoValidCode];
				} else {
					[self.collector recordReception: @"noaudio" at: [self.clock now]];
					VL_LOG_EVENT(@"noReception", [self.clock now], @"noaudio");
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

@end
