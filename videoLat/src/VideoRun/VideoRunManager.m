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

- (int) initialPrepareCount { return 10; }
- (int) initialPrepareDelay { return 1000; }

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"QR Code Roundtrip"];
    [BaseRunManager registerNib: @"VideoRun" forMeasurementType: @"QR Code Roundtrip"];
#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"QR Code Roundtrip"];
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
}

#pragma mark RunOutputManagerProtocol

- (void)triggerNewOutputValue
{
    outputCodeImage = nil;
    [super triggerNewOutputValue];
}

- (CIImage *)getNewOutputImage
{
    assert(handlesOutput);
    assert(self.genner);
    // Called from the redraw routine, should generate a new output code only when needed.
    @synchronized(self) {
        // If we have already generated a QR code that hasn't been detected yet we return that.
        if (outputCodeImage)
            return outputCodeImage;
        [self getNewOutputCode];
        
        CGSize size = {480, 480};
        assert(self.genner);
        outputCodeImage = [self.genner genImageForCode:self.outputCode size:size.width];
        assert(outputCodeImage);
        // Set outputCodeTimestamp to 0 to signal we have not reported this outputcode yet
        outputCodeTimestamp = 0;
        return outputCodeImage;
    }
}

- (NSString *)getNewOutputCode
{
    // Called from the redraw routine, should generate a new output code only when needed.
    @synchronized(self) {
        
        // If we are not running we should display a blue-grayish square
        if (!self.running && !self.preparing) {
            self.outputCode =  @"undefined";
            return self.outputCode;
        }
        uint64_t tsForCode = [self.clock now];
        // Sanity check: times should be monotonically increasing
        if (outputCodeTimestamp && outputCodeTimestamp >= tsForCode) {
            showWarningAlert(@"Output clock has gone back in time");
        }
        
        // Generate the new output code. During preRunning, our input device can
        // supply the codes, if it wants to (the NetworkInput does this, so the
        // codes contain the ip/port combination of the server)
        self.prevOutputCode = self.outputCode;
        self.outputCode = nil;
        if (self.preparing && [self.inputCompanion.capturer respondsToSelector:@selector(genPrepareCode)]) {
            self.outputCode = [self.inputCompanion.capturer genPrepareCode];
        }
        if (self.outputCode == nil) {
            self.outputCode = [NSString stringWithFormat:@"%lld", tsForCode];
        }
        if (VL_DEBUG) NSLog(@"New output code: %@", self.outputCode);
        // Set outputCodeTimestamp to 0 to signal we have not reported this outputcode yet
        outputCodeTimestamp = 0;
        return self.outputCode;
    }
}

#pragma mark RunInputManagerProtocol

- (void) newInputDone: (CVImageBufferRef)image at:(uint64_t)inputCodeTimestamp
{
    assert(handlesInput);
    assert(self.finder);
    @synchronized(self) {
		if (self.outputCompanion.outputCode == nil) {
			if (VL_DEBUG) NSLog(@"newInputDone called, but no output code yet\n");
			return;
		}
        uint64_t finderStartTime = [self.clock now];
        NSString *inputCode = [self.finder find: image];
        uint64_t finderStopTime = [self.clock now];
        uint64_t finderDuration = finderStopTime - finderStartTime;
        if (inputCode == NULL) {
            // Nothing found.
            if (self.preparing) {
                [self prepareReceivedNoValidCode];
            }
            return;
        }
        if (self.outputCompanion.outputCode == nil) {
            if (VL_DEBUG) NSLog(@"newInputDone called, but no output code yet\n");
            return;
        }
        if ([inputCode isEqualToString:@"undetectable"]) {
            // black/white detector needs to be kicked (black and white levels have come too close)
            NSLog(@"Detector range too small, generating new code");
            [self.outputCompanion triggerNewOutputValue];
            return;
        }
        if ([inputCode isEqualToString:@"uncertain"]) {
            // Unsure what we have detected. Leave it be for a while then change.
            prevInputCodeDetectionCount++;
            if (prevInputCodeDetectionCount % 250 == 0) {
                NSLog(@"Received uncertain code for too long. Generating new one.");
                [self.outputCompanion triggerNewOutputValue];
            }
            return;
        }
        // Compare the code to what was expected.
        if (self.outputCompanion.prevOutputCode && [inputCode isEqualToString:self.outputCompanion.prevOutputCode]) {
            if (VL_DEBUG) NSLog(@"Received old output code again: %@", inputCode);
            return;
        }
        if (prevInputCode && [inputCode isEqualToString: prevInputCode]) {
            prevInputCodeDetectionCount++;
            if (prevInputCodeDetectionCount == 3) {
                // Aftter we've detected 3 frames with the right light level
                // we generate a new one.
                [self.outputCompanion triggerNewOutputValueAfterDelay];
            }
            if (VL_DEBUG) NSLog(@"Received same code as last reception: %@, count=%d", inputCode, prevInputCodeDetectionCount);
            if ((prevInputCodeDetectionCount % 250) == 0) {
                showWarningAlert(@"Old QR-code detected too often. Generating new one.");
                [self.outputCompanion triggerNewOutputValue];
            }
        } else if ([inputCode isEqualToString: self.outputCompanion.outputCode]) {
            // Correct code found.
            
            // Let's first report it.
            if (self.running) {
                if (inputCodeTimestamp == 0) {
                    showWarningAlert(@"newInputDone called before newInputStart was called");
                }
                BOOL ok = [self.collector recordReception: self.outputCompanion.outputCode at: inputCodeTimestamp];
                if (!ok) {
                    NSLog(@"Received code %@ before it was transmitted", self.outputCompanion.outputCode);
                    return;
                }
                VL_LOG_EVENT(@"reception", inputCodeTimestamp, self.outputCompanion.outputCode);
                inputCodeTimestamp = 0;
                self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
                self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
                [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
            } else if (self.preparing) {
                // Compute average duration of our code detection algorithm
                if (averageFinderDuration == 0)
                    averageFinderDuration = finderDuration;
                else
                    averageFinderDuration = (averageFinderDuration+finderDuration)/2;
                // Notify the detection
                [self prepareReceivedValidCode: inputCode];
            }
            // Now let's remember it so we don't generate "bad code" messages
            // if we detect it a second time.
            prevInputCode = self.outputCompanion.outputCode;
            prevInputCodeDetectionCount = 0;
            if (VL_DEBUG) NSLog(@"Received: %@", self.outputCompanion.outputCode);
            // Generate new output code later, after we've detected this one a few times.
        } else {
            // We have transmitted a code, but received a different one??
            if (self.running) {
                NSLog(@"Bad data: expected %@, got %@", self.outputCompanion.outputCode, inputCode);
#if 0
                showWarningAlert([NSString stringWithFormat:@"Received unexpected QR-code %@", inputCode]);
                [self.outputCompanion triggerNewOutputValue];
#endif
            } else if (self.preparing) {
                [self prepareReceivedNoValidCode];
                prevInputCode = nil;
            }
        }
        // While idle, change output value once in a while
        if (!self.running && !self.preparing) {
            [self.outputCompanion triggerNewOutputValue];
        }
   }
}

- (void)setFinderRect: (NSorUIRect)theRect
{
    assert(handlesInput);
    assert(self.finder);
    if ([self.finder respondsToSelector:@selector(setSensitiveArea:)]) {
        [self.finder setSensitiveArea: theRect];
    }
}

@end
