//
//  OutputManager.m
//
//  Created by Jack Jansen on 27-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "VideoRunManager.h"
#import "PythonSwitcher.h"
#import "FindQRCodes.h"
#import "GenQRCodes.h"

@implementation VideoRunManager
@synthesize useQRcode;
@synthesize mirrored;

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Roundtrip"];
    [BaseRunManager registerNib: @"VideoRunManager" forMeasurementType: @"Video Roundtrip"];
}

- (VideoRunManager*)init
{
	if (self) {
        _measurementTypeName = @"Video Roundtrip";
		foundQRcode = false;
		found_total = 0;
		found_ok = 0;
		current_qrcode = NULL;
		outputAddedOverhead = 0;
		outputStartTime = 0;
		inputAddedOverhead = 0;
		inputStartTime = 0;
		outputCode = nil;
		outputCodeHasBeenReported = true;
		lastOutputCode = nil;
		lastInputCode = nil;
		capturer = nil;
	}
    return self;
}

- (void) awakeFromNib
{
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
    @synchronized(self) {
//        [[settings window] setReleasedWhenClosed: false];

        genner = [[GenQRcodes alloc] init];
        finder = [[FindQRcodes alloc] init];
        statusView = measurementMaster.statusView;
        collector = measurementMaster.collector;
    }
}

- (void)selectMeasurementType: (NSString *)typeName
{
	[super selectMeasurementType:typeName];
	if (!selectionView) {
		// XXXJACK Make sure selectionView is active/visible
	}
	[selectionView.bPreRun setEnabled: YES];
	[selectionView.bRun setEnabled: NO];
	if (statusView) {
		[statusView.bStop setEnabled: NO];
	}
}

- (void)_triggerNewOutputValue
{
	// XXXJACK can be simplified
	[outputView showNewData];
}

- (void)reportDataCapturer: (id)capt
{
    capturer = capt;
}

- (IBAction)startPreMeasuring: (id)sender
{
	// XXXJACK Disable measurement selection button in RunTypeView
	[selectionView.bPreRun setEnabled: NO];
	[selectionView.bRun setEnabled: NO];
	if (statusView) {
		[statusView.bStop setEnabled: NO];
	}
	// XXXJACK premeasuring not yet implemented.
	[self stopPreMeasuring: self];
}

- (IBAction)stopPreMeasuring: (id)sender
{
	[selectionView.bPreRun setEnabled: NO];
	[selectionView.bRun setEnabled: YES];
	if (!statusView) {
		// XXXJACK Make sure statusview is active/visible
	}
	[statusView.bStop setEnabled: NO];
}

- (IBAction)startMeasuring: (id)sender
{
    @synchronized(self) {
		[selectionView.bPreRun setEnabled: NO];
		[selectionView.bRun setEnabled: NO];
		if (!statusView) {
			// XXXJACK Make sure statusview is active/visible
		}
		[statusView.bStop setEnabled: YES];
        self.running = YES;
        self.useQRcode = YES;
        self.mirrored = NO;
        [capturer startCapturing];
        [collector startCollecting: self.measurementTypeName input: capturer.deviceID name: capturer.deviceName output: outputView.deviceID name: outputView.deviceName];
        outputView.mirrored = self.mirrored;
        [self _triggerNewOutputValue];
    }
}

#pragma mark SettingsChangedProtocol
#if 0
- (void)settingsChanged: (id)sender
{
    // XYZZY get from Type popup
    self.useQRcode = YES;
    self.mirrored = NO;
}

- (void)settingsChanged
{
    @synchronized(self) {
        if (current_qrcode) {
            current_qrcode = nil;
        }
		if (outputView) {
			outputView.mirrored = settings.mirrorView;
			outputView.visible = settings.xmit;
		}
        if ([settings.coordHelper isEqualToString: @"None"]) {
			delegate = nil;
		} else {
			if (delegate && ![settings.coordHelper isEqualToString: [delegate script]]) {
				delegate = nil;
			}
            if (delegate == nil) { 
                delegate = [[PythonSwitcher alloc] initWithScript: settings.coordHelper];
                if ([delegate hasInput]) {
                    [self performSelector: @selector(_mono_pollInput) withObject: nil afterDelay:(NSTimeInterval)0.001]; 
                }
			}
		}
        [self _triggerNewOutputValue];
    }
}
#endif

#pragma mark MeasurementOutputManagerProtocol

- (CIImage *)newOutputStart
{
    @synchronized(self) {
        CIImage *newImage = nil;
        if (!self.running) {
            newImage = [CIImage imageWithColor:[CIColor colorWithRed:0.1 green:0.4 blue:0.5]];
            CGRect rect = {0, 0, 480, 480};
            newImage = [newImage imageByCroppingToRect: rect];
            return newImage;
        }
        if (outputStartTime == 0) outputStartTime = [collector now];
        outputAddedOverhead = 0;
        // We create a new image if either the previous one has been detected, or
        // if we are free-running.
        bool wantNewImage = (current_qrcode == NULL);

        if (!wantNewImage) {
            newImage = current_qrcode;
        } else {
            outputCode = [NSString stringWithFormat:@"%lld", outputStartTime];
            assert(outputCodeHasBeenReported);
            outputCodeHasBeenReported = false;
            if (delegate && [delegate respondsToSelector:@selector(newOutput:)]) {
                NSString *new = [delegate newOutput: outputCode];
                if (new) {
                    // Delegate decided to wait for something else, we transmit black
                    newImage = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]];
                    CGRect rect = {0, 0, 480, 480};
                    newImage = [newImage imageByCroppingToRect: rect];
                    current_qrcode = newImage;
                    outputCode = new;
                    return newImage;
                }
            }
            char *bitmapdata = (char*)malloc(480*480*4);
            memset(bitmapdata, 0xf0, 480*480*4);
            [genner gen: bitmapdata width: 480 height: 480 code: [outputCode UTF8String]];
            NSData *data = [NSData dataWithBytesNoCopy:bitmapdata length:sizeof(bitmapdata) freeWhenDone: YES];
            CGSize size = {480, 480};
            newImage = [CIImage imageWithBitmapData:data bytesPerRow:4*480 size:size format: kCIFormatARGB8 colorSpace: nil];
            current_qrcode = newImage;
#if 0
            // Debug: detect our own QRcode
            bool found = [finder find: bitmapdata width: 640 height: 480 format: "RGB4" size:640*480*4];
            NSLog(@"QRcode finder test returned %d", (int)found);
#endif
        }
        return newImage;
    }
}

- (void) newOutputDone
{
    @synchronized(self) {
        if (outputStartTime == 0 || outputCodeHasBeenReported) return;
        assert(outputAddedOverhead < [collector now]);
        assert(strcmp([outputCode UTF8String], "BadCookie") != 0);
		uint64_t outputTime = [collector now] - outputAddedOverhead;
		if (self.running)
			[collector recordTransmission: outputCode at: outputTime];
        outputCodeHasBeenReported = true;
        outputStartTime = 0;
        outputAddedOverhead = 0;
    }
}

- (void) updateOutputOverhead: (double) deltaT
{
    @synchronized(self) {
        assert(deltaT < 1.0);
        if (outputStartTime != 0) {
            assert(outputAddedOverhead < [collector now]);
            outputAddedOverhead = (uint64_t)(deltaT*1000000.0);
        }
    }
}

#pragma mark MeasurementInputManagerProtocol

- (void)setFinderRect: (NSRect)theRect
{
//xyzzy	status.finderRect = theRect;
	[statusView update: self];
}


- (void) newInputStart
{
    @synchronized(self) {
//    assert(inputStartTime == 0);
        if (collector) {
            inputStartTime = [collector now];
            inputAddedOverhead = 0;
        }
    }
}

- (void) newInputDone
{
    @synchronized(self) {
        inputStartTime = 0;
    }
}

- (void) newInputDone: (void*)buffer width: (int)w height: (int)h format: (const char*)formatStr size: (int)size
{
    @synchronized(self) {
        if (inputStartTime == 0) {
            /*DBG*/ NSLog(@"newInputDone called, but inputStartTime==0\n");
            return;
        }
		if (outputCode == nil) { NSLog(@"newInputDone called, but no output code yet\n"); return; }
        assert(inputStartTime != 0);
            
        char *code = [finder find: buffer width: w height: h format: formatStr size:size];
        foundQRcode = (code != NULL);
        if (foundQRcode) {
			// If we are in automatic mode, we compare the code to what was
			// expected.
			if (strcmp(code, [outputCode UTF8String]) == 0) {
				// outputStartTime = 0;
				// Correct. Prepare for creating a new QRcode.
				//XXX [self performSelectorOnMainThread: @selector(_triggerNewOutputValue) withObject: nil waitUntilDone: NO];
				if (current_qrcode == nil) {
					// We found the last one already, don't count it again.
					return;
				}
				current_qrcode = nil;
				lastOutputCode = outputCode;
				assert(outputCodeHasBeenReported);
				outputCode = [NSString stringWithFormat: @"BadCookie"];
			} else if (strcmp(code, [lastOutputCode UTF8String]) == 0) {
				// We have received the previous code again. Ignore.
				//NSLog(@"Same old code again: %s", code);
			} else {
				// We have transmitted a code, but received a different one??
				NSLog(@"Bad data: expected %@, got %s", outputCode, code);
				inputAddedOverhead = 0;
				inputStartTime = 0;
				[self performSelectorOnMainThread: @selector(_triggerNewOutputValue) withObject: nil waitUntilDone: NO];
				return;
			}
            if (!lastInputCode || strcmp(code, [lastInputCode UTF8String]) != 0) {
                found_ok++;
                found_total++;
                lastInputCode = [NSString stringWithUTF8String: code];
				if (self.running)
					[collector recordReception: lastInputCode at: inputStartTime-inputAddedOverhead];
            }
            inputAddedOverhead = 0;
            // Remember rectangle (for black/white detection)
//xyzzy            status.finderRect = finder.rect;
            [self performSelectorOnMainThread: @selector(_triggerNewOutputValue) withObject: nil waitUntilDone: NO];
        } else {
            found_total++;
            inputAddedOverhead = 0;
        }
        inputStartTime = 0;
		if (self.running) {
			statusView.detectCount = [NSString stringWithFormat: @"%d", collector.count];
			statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", collector.average / 1000.0, collector.stddev / 1000.0];
		}
        [statusView update: self];
    }
}

- (void) updateInputOverhead: (double) deltaT
{
    @synchronized(self) {
        if(inputStartTime != 0)
            inputAddedOverhead = (uint64_t)(deltaT*1000000.0);
    }
}


@end
