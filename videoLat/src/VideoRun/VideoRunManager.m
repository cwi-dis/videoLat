//
//  VideoRunManager.m
//
//  Created by Jack Jansen on 27-08-10.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "VideoRunManager.h"
#import "FindQRcode.h"
#import "GenQRcode.h"
#import "EventLogger.h"
#import <sys/sysctl.h>


@implementation VideoRunManager
@synthesize selectionView;
@synthesize clock;

//
// Prerun parameters.
// We want 10 consecutive catches, and we initially start with a 1ms delay (doubled at every failure)

- (int) initialPrerunCount { return 10; }
- (int) initialPrerunDelay { return 1000; }

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Roundtrip"];
    [BaseRunManager registerNib: @"VideoRun" forMeasurementType: @"Video Roundtrip"];
#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"Video Roundtrip"];
#endif
}

- (VideoRunManager*)init
{
    self = [super init];
	if (self) {
		outputCodeImage = nil;

        prevInputCode = nil;
	}
    return self;
}

- (void)dealloc
{
    // Deallocate the capturer first
    self.capturer = nil;
	self.clock = nil;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    assert(self.clock);
    if (handlesInput) {
        assert(self.finder);
        assert(self.clock);
    } else {
        assert(self.inputCompanion);
        assert(self.capturer == nil);
        assert(self.clock);
        assert(self.clock == self.inputCompanion.clock);
    }
    if (handlesOutput) {
        assert(self.genner);
    }
#ifdef WITH_APPKIT
    assert(self.selectionView);
#endif
}

- (void)stop
{
	if (self.capturer) [self.capturer stop];
	self.capturer = nil;
	self.clock = nil;
}


- (void) _prerunRecordNoReception
{
#if 1
    if (VL_DEBUG) NSLog(@"Prerun no reception\n");
    assert(self.preRunning);
    if (outputFrameLatestTimestamp && [self.clock now] - outputFrameLatestTimestamp > maxDelay) {
        // No data found within alotted time. Double the time, reset the count, change mirroring
        if (VL_DEBUG) NSLog(@"tsOutLatest=%llu, prerunDelay=%llu\n", outputFrameLatestTimestamp, maxDelay);
        maxDelay *= 2;
        prerunMoreNeeded = self.initialPrerunCount;
        self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prerunMoreNeeded];
		self.statusView.detectAverage = @"";
        [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
        [self.outputCompanion triggerNewOutputValue];
    } 
#endif
}

- (void) _prerunRecordReception: (NSString *)code
{
    if (VL_DEBUG) NSLog(@"prerun reception %@\n", code);
    assert(self.preRunning);
    if (self.preRunning) {
        prerunMoreNeeded -= 1;
        self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prerunMoreNeeded];
		self.statusView.detectAverage = @"";
        [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
        if (VL_DEBUG) NSLog(@"preRunMoreMeeded=%d\n", prerunMoreNeeded);
        if (prerunMoreNeeded == 0) {
            NSLog(@"average detection algorithm duration=%lld µS", averageFinderDuration);
#ifdef WITH_SET_MIN_CAPTURE_DURATION
            [self.capturer setMinCaptureInterval: averageFinderDuration*2];
#endif
            self.statusView.detectCount = @"";
			self.statusView.detectAverage = @"";
            [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
            [self performSelectorOnMainThread: @selector(stopPreMeasuring:) withObject: self waitUntilDone: NO];
        }
    }
}

- (void) _newOutputCode
{
	uint64_t tsForCode = [self.clock now];
	// Sanity check: times should be monotonically increasing
	if (outputFrameLatestTimestamp && outputFrameLatestTimestamp >= tsForCode) {
		showWarningAlert(@"Output clock has gone back in time");
	}
	
	// Generate the new output code. During preRunning, our input companion can
	// supply the codes, if it wants to (the NetworkRunManager does this, so the
	// codes contain the ip/port combination of the server)
	self.prevOutputCode = self.outputCode;
	self.outputCode = nil;
	if (self.preRunning && [self.inputCompanion respondsToSelector:@selector(genPrerunCode)]) {
		self.outputCode = [self.inputCompanion genPrerunCode];
	}
	if (self.outputCode == nil) {
		self.outputCode = [NSString stringWithFormat:@"%lld", tsForCode];
	}
	if (VL_DEBUG) NSLog(@"New output code: %@", self.outputCode);
}

#pragma mark RunOutputManagerProtocol

- (void)triggerNewOutputValue
{
	assert(handlesOutput);
	@synchronized(self) {
		outputCodeImage = nil;
		[self.outputView performSelectorOnMainThread:@selector(showNewData) withObject:nil waitUntilDone:NO ];
	}
}

- (CIImage *)newOutputStart
{
    // Called from the redraw routine, should generate a new output code only when needed.
    @synchronized(self) {
        
        // If we are not running we should display a blue-grayish square
        if (!self.running && !self.preRunning) {
            CIImage *idleImage = [CIImage imageWithColor:[CIColor colorWithRed:0.1 green:0.4 blue:0.5]];
            CGRect rect = {0, 0, 480, 480};
            idleImage = [idleImage imageByCroppingToRect: rect];
            return idleImage;
        }
        
        // If we have already generated a QR code that hasn't been detected yet we return that.
        if (outputCodeImage)
            return outputCodeImage;
        [self _newOutputCode];

        CGSize size = {480, 480};
        assert(self.genner);
        outputCodeImage = [self.genner genImageForCode:self.outputCode size:size.width];
        assert(outputCodeImage);
		outputFrameEarliestTimestamp = [self.clock now];
		outputFrameLatestTimestamp = 0;
		return outputCodeImage;
    }
}

- (void) newOutputDone
{
    @synchronized(self) {
		if (outputFrameEarliestTimestamp == 0) {
			// We haven't generated an output code yet, so ignore this, a redraw
			// because of some other reason
			return;
		}
		if (outputFrameLatestTimestamp != 0) {
			// We have already received the redraw for our mosyt recent generated code.
			// Again, redraw for some other reason, ignore.
			return;
		}
        assert(outputFrameEarliestTimestamp);
		assert(outputFrameLatestTimestamp == 0);
		outputFrameLatestTimestamp = [self.clock now];
		uint64_t tsOutToRemember = outputFrameLatestTimestamp;
		if (self.running) {
			[self.collector recordTransmission: self.outputCode at: tsOutToRemember];
			VL_LOG_EVENT(@"transmission", tsOutToRemember, self.outputCode);
        }
    }
}

#pragma mark RunInputManagerProtocol

- (void) newInputDone: (CVImageBufferRef)image
{
    @synchronized(self) {
		if (self.outputCompanion.outputCode == nil) {
			if (VL_DEBUG) NSLog(@"newInputDone called, but no output code yet\n");
			return;
		}
        uint64_t finderStartTime = [self.clock now];
        NSString *inputCode = [self.finder find: image];
        uint64_t finderStopTime = [self.clock now];
        uint64_t finderDuration = finderStopTime - finderStartTime;
        BOOL foundQRcode = (inputCode != NULL);
        if (foundQRcode) {
            
			// Compare the code to what was expected.
            if (self.outputCompanion.prevOutputCode && [inputCode isEqualToString:self.outputCompanion.prevOutputCode]) {
				if (VL_DEBUG) NSLog(@"Received old output code again: %@", inputCode);
            } else if (prevInputCode && [inputCode isEqualToString: prevInputCode]) {
                prevInputCodeDetectionCount++;
                if (VL_DEBUG) NSLog(@"Received same code as last reception: %@, count=%d", inputCode, prevInputCodeDetectionCount);
                if ((prevInputCodeDetectionCount % 250) == 0) {
                    showWarningAlert(@"Old QR-code detected too often. Generating new one.");
                    [self.outputCompanion triggerNewOutputValue];
                }
            } else if ([inputCode isEqualToString: self.outputCompanion.outputCode]) {
				// Correct code found.
                
                // Let's first report it.
				if (self.running) {
                    if (inputFrameTimestamp == 0) {
                        showWarningAlert(@"newInputDone called before newInputStart was called");
                    }
					BOOL ok = [self.collector recordReception: self.outputCompanion.outputCode at: inputFrameTimestamp];
					VL_LOG_EVENT(@"reception", inputFrameTimestamp, self.outputCompanion.outputCode);
                    inputFrameTimestamp = 0;
                    if (!ok) {
						showWarningAlert([NSString stringWithFormat:@"Received code %@ before it was transmitted", self.outputCompanion.outputCode]);
                    }
                } else if (self.preRunning) {
                    // Compute average duration of our code detection algorithm
                    if (averageFinderDuration == 0)
                        averageFinderDuration = finderDuration;
                    else
                        averageFinderDuration = (averageFinderDuration+finderDuration)/2;
                    // Notify the detection
                    [self _prerunRecordReception: inputCode];
                }
                // Now do a sanity check that it is greater than the previous detected code
                if (prevInputCode && [prevInputCode length] >= [self.outputCompanion.outputCode length] && [prevInputCode compare:self.outputCompanion.outputCode] >= 0) {
					showWarningAlert(@"Warning: input QR-code not monotonically increasing.");
                }
                // Now let's remember it so we don't generate "bad code" messages
                // if we detect it a second time.
                prevInputCode = self.outputCompanion.outputCode;
                prevInputCodeDetectionCount = 0;
                if (VL_DEBUG) NSLog(@"Received: %@", self.outputCompanion.outputCode);
                // Now generate a new output code.
                [self.outputCompanion triggerNewOutputValueAfterDelay];
			} else {
				// We have transmitted a code, but received a different one??
                if (self.running) {
                    NSLog(@"Bad data: expected %@, got %@", self.outputCompanion.outputCode, inputCode);
					showWarningAlert([NSString stringWithFormat:@"Received unexpected QR-code %@", inputCode]);
					[self.outputCompanion triggerNewOutputValue];
                } else if (self.preRunning) {
					[self _prerunRecordNoReception];
				}
			}
        } else {
             
            if (self.preRunning) {
                [self _prerunRecordNoReception];
            }
        }
		if (self.running) {
			self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
			self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
            [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
		}
    }
}

- (void)setFinderRect: (NSorUIRect)theRect
{
#if 0
	[self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
#endif
}


- (void) newInputStart:(uint64_t)timestamp
{
    NSString *warning = NULL;
    @synchronized(self) {
//    assert(inputStartTime == 0);
#ifdef WITH_FRAMETIME_COMPUTE
        if (self.collector) {
			tsFrameEarliest = tsFrameLatest;
			tsFrameLatest = timestamp;

            // Sanity check: times should be monotonically increasing
            if (tsFrameEarliest > tsFrameLatest) {
                warning = [NSString stringWithFormat: @"Input clock has gone back in time, got %lld after %lld", tsFrameLatest, tsFrameEarliest];
            }
        }
#else
        inputFrameTimestamp = timestamp;
#endif
    }
    if (warning) showWarningAlert(warning);

}

@end
