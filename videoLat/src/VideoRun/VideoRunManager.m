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
#import "NetworkIODevice.h"


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
    // Obviously we are responsible for QR-code roundtrip measurements
    [BaseRunManager registerClass: [self class] forMeasurementType: @"QR Code Roundtrip"];
    [BaseRunManager registerNib: @"VideoRun" forMeasurementType: @"QR Code Roundtrip"];
    // We are also responsible for QR-code roundtrip calibrations
    [BaseRunManager registerClass: [self class] forMeasurementType: @"QR Code Roundtrip Calibrate"];
    [BaseRunManager registerNib: @"VideoCalibrationRun" forMeasurementType: @"QR Code Roundtrip Calibrate"];
    // We also register ourselves for send-only, as a helper. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"QR Code Transmission"];
    [BaseRunManager registerNib: @"VideoSenderRun" forMeasurementType: @"QR Code Transmission"];
    // And we handle camera and screen calibrations using a second networked device
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Reception Calibrate using Other Device"];
    [BaseRunManager registerNib: @"CalibrateCameraFromRemoteScreen" forMeasurementType: @"Reception Calibrate using Other Device"];
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Transmission Calibrate using Other Device"];
    [BaseRunManager registerNib: @"CalibrateScreenFromRemoteCamera" forMeasurementType: @"Transmission Calibrate using Other Device"];

#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"QR Code Roundtrip"];
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"QR Code Roundtrip Calibrate"];
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"Reception Calibrate using Other Device"];
    [BaseRunManager registerSelectionNib: @"NetworkInputSelectionView" forMeasurementType: @"QR Code Transmission"];
    [BaseRunManager registerSelectionNib: @"NetworkInputSelectionView" forMeasurementType: @"Transmission Calibrate using Other Device"];
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

- (void)triggerNewOutputValue
{
    outputCodeImage = nil;
    [super triggerNewOutputValue];
}

- (CIImage *)getNewOutputImage
{
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
            self.outputCode = nil;
            if (self.networkIODevice) {
                self.outputCode = [self.networkIODevice genPrepareCode];
            }
            if (!self.outputCode) {
                self.outputCode =  @"undefined";
            }
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
        if (self.preparing && self.networkIODevice) {
            self.outputCode = [self.networkIODevice genPrepareCode];
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

- (void) newInputDone: (CVImageBufferRef)image at:(uint64_t)inputTimestamp
{
    assert(self.finder);
    @synchronized(self) {
        uint64_t finderStartTime = [self.clock now];
        NSString *inputCode = [self.finder find: image];
        uint64_t finderStopTime = [self.clock now];
        if (self.preparing) {
            // Compute average duration of our code detection algorithm
            uint64_t finderDuration = finderStopTime - finderStartTime;
            if (averageFinderDuration == 0)
                averageFinderDuration = finderDuration;
            else
                averageFinderDuration = (averageFinderDuration+finderDuration)/2;
        }
        if (inputCode == NULL) {
            // Nothing found.
            inputCode = @"uncertain";
        }
        [self newInputDone: inputCode count: 1 at: inputTimestamp];
    }
}
#if 0

#endif
- (void)setFinderRect: (NSorUIRect)theRect
{
    assert(self.finder);
    if ([self.finder respondsToSelector:@selector(setSensitiveArea:)]) {
        [self.finder setSensitiveArea: theRect];
    }
}

@end
