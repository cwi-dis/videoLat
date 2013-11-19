//
//  OutputManager.m
//
//  Created by Jack Jansen on 27-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "Manager.h"
#import "PythonSwitcher.h"
#import "FindQRCodes.h"
#import "GenQRCodes.h"

@implementation Manager
@synthesize running;
@synthesize useQRcode;
@synthesize mirrored;

- (Manager*)init
{
    self = [super init];
	if (self) {
		foundQRcode = false;
		found_total = 0;
		found_ok = 0;
		current_qrcode = NULL;
		blacklevel = 255;
		whitelevel = 0;
		nBWdetections = 0;
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
    @synchronized(self) {
//        [[settings window] setReleasedWhenClosed: false];

        genner = [[GenQRcodes alloc] init];
        finder = [[FindQRcodes alloc] init];
    }
}

- (void)_triggerNewOutputValue
{
	if (outputView.visible) {
		[outputView showNewData];
	} else {
		[self _mono_showNewData];
	}
}

- (void)reportDataCapturer: (id)capt
{
    capturer = capt;
}

- (IBAction)startMeasuring: (id)sender
{
    @synchronized(self) {
        self.running = YES;
        self.useQRcode = YES;
        self.mirrored = NO;
        [capturer startCapturing];
        [collector startCollecting: nil input: capturer.deviceID name: capturer.deviceName output: outputView.deviceID name: outputView.deviceName];
        outputView.mirrored = self.mirrored;
        [self _triggerNewOutputValue];
    }
}

- (IBAction)stopMeasuring: (id)sender
{
    self.running = false;
	[collector stopCollecting];
	[collector trim];
	status.detectCount = [NSString stringWithFormat: @"%d (after trimming 5%%)", collector.count];
	status.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", collector.average / 1000.0, collector.stddev / 1000.0];
	[status update: self];
    [self.document newDocumentComplete: self];
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
        if (!self.running /* || !settings.xmit */) {
            newImage = [CIImage imageWithColor:[CIColor colorWithRed:0.1 green:0.4 blue:0.5]];
            CGRect rect = {0, 0, 480, 480};
            newImage = [newImage imageByCroppingToRect: rect];
            return newImage;
        }
        if (outputStartTime == 0) outputStartTime = [collector now];
        outputAddedOverhead = 0;
#if 0
        if (settings.datatypeBlackWhite) {
            // XXX Do black/white
            [self _mono_showNewData];
            if (currentColorIsWhite) 
                newImage = [CIImage imageWithColor:[CIColor colorWithRed:1 green:1 blue:1]];
            else
                newImage = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]];
            CGRect rect = {0, 0, 480, 480};
            newImage = [newImage imageByCroppingToRect: rect];
            return newImage;
        }
#endif
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
        if (self.useQRcode) {
            [collector recordTransmission: outputCode at: outputTime];
        } else {
            [collector recordTransmission: currentColorIsWhite?@"white":@"black" at: outputTime];
        }
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
	[status update: self];
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
        /*DBG*/ if (inputStartTime == 0) { NSLog(@"newInputDone called, but inputStartTime==0\n"); return; }
		if (outputCode == nil) { NSLog(@"newInputDone called, but no output code yet\n"); return; }
        assert(inputStartTime != 0);
        if (self.running && !self.useQRcode) {
			goto mono;
        }
                
            
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
			status.detectCount = [NSString stringWithFormat: @"%d", collector.count];
			status.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", collector.average / 1000.0, collector.stddev / 1000.0];
		}
        [status update: self];
    }
	return;
mono:
	[self _mono_newInputDone:buffer width:w height:h format:formatStr size:size];
}

- (void) updateInputOverhead: (double) deltaT
{
    @synchronized(self) {
        if(inputStartTime != 0)
            inputAddedOverhead = (uint64_t)(deltaT*1000000.0);
    }
}

#pragma mark Monochrome support

- (void) _mono_newInputDone: (bool)isWhite
{
	uint64_t receptionTime = [collector now];
    @synchronized(self) {
        assert(inputStartTime != 0);
        if (!self.running || self.useQRcode) return;

        if (isWhite == currentColorIsWhite) {
            // Found it! Invert for the next round
            currentColorIsWhite = !currentColorIsWhite;
            nBWdetections++;
//xyzzy            status.bwString = [NSString stringWithFormat: @"found %d (current %s)", nBWdetections, isWhite?"white":"black"];
            [status update: self];
            // XXXJACK Is this correct? is "now" the best timestamp we have for the incoming hardware data?
            [collector recordReception: isWhite?@"white":@"black" at: receptionTime];
            inputAddedOverhead = 0;
            outputCode = [NSString stringWithFormat:@"%lld", receptionTime];
            outputCodeHasBeenReported = false;
            [self performSelectorOnMainThread: @selector(_triggerNewOutputValue) withObject: nil waitUntilDone: NO];

        }
        inputStartTime = 0;
    }
}

- (void) _mono_newInputDone: (void*)buffer width: (int)w height: (int)h format: (const char*)formatStr size: (int)size
{
    @synchronized(self) {
		// Wait for black/white, if possible
#if 0
		NSRect area = status.finderRect; // XXXJACK This is bad: using status for storing the rect
		if (NSIsEmptyRect(area)) {
			settings.recv = false;
			[status update: self];
			inputStartTime = 0;
			goto bad;
		}
		// Detect black/white
		int pixelstep, pixelstart;
		if (strcmp(formatStr, "Y800") == 0) {
			pixelstep = 1;
			pixelstart = 0;
		} else if (strcmp(formatStr, "YUYV") == 0) {
			pixelstep = 2;
			pixelstart = 0;
		} else if (strcmp(formatStr, "UYVY") == 0) {
			pixelstep = 2;
			pixelstart = 1;
		} else {
			settings.recv = false;
			[status update: self];
			inputStartTime = 0;
			goto bad2;
		}
		int minx, x, maxx, miny, y, maxy, ystep;
		minx = area.origin.x + (area.size.width/4);
		maxx = minx + (area.size.width/2);
		miny = area.origin.y + (area.size.height/4);
		maxy = miny + (area.size.width/2);
		ystep = w*pixelstep;
		long long total = 0;
		long count = 0;
		for (y=miny; y<maxy; y++) {
			for (x=minx; x<maxx; x++) {
				unsigned char *pixelPtr = (unsigned char *)buffer + pixelstart + y*ystep + x*pixelstep;
				total += *pixelPtr;
				count++;
			}
		}
		int average = (int)(total/count);
		//NSLog(@"Average greylevel is %d (black %d, white %d, #%d) want %s\n", average, blacklevel, whitelevel, nBWdetections, currentColorIsWhite?"white":"black");
		if (average < blacklevel) blacklevel = average;
		if (average > whitelevel) whitelevel = average;
		bool foundColorIsWhite = average > (whitelevel+blacklevel) / 2;
		if (foundColorIsWhite == currentColorIsWhite) {
			// Found it! Invert for the next round
			currentColorIsWhite = !currentColorIsWhite;
			nBWdetections++;
			status.bwString = [NSString stringWithFormat: @"found %d (levels %d..%d)", nBWdetections, blacklevel, whitelevel];
			[status update: self];
			if (nBWdetections > 10) {
				// The first 10 are for calibrating, then we get to business
                [collector recordReception: foundColorIsWhite?@"white":@"black" at: inputStartTime-inputAddedOverhead];
				inputAddedOverhead = 0;
			}
			outputCode = [NSString stringWithFormat:@"%lld", [collector now]];
			outputCodeHasBeenReported = false;
			[self performSelectorOnMainThread: @selector(_triggerNewOutputValue) withObject: nil waitUntilDone: NO];

		}
		inputStartTime = 0;
#endif
	}
    return;
	// Bah. @synchronised means we can't really do error messages in the normal place,
	// it may lead to a deadlock if the mainloop needs the lock.
bad:
	NSRunAlertPanel(
		@"Alert",
		@"Please detect at least one QRcode first to determine position.", 
		nil, nil, nil);
	return;
bad2:
	NSRunAlertPanel(
		@"Alert",
		@"Black/White detection only implemented for greyscale capture, not \"%s\".", 
		nil, nil, nil,
		formatStr);
}

- (void)_mono_pollInput
{
    @synchronized(self) {
        if (delegate == nil || ![delegate hasInput]) return;
        [self newInputStart];
        bool result = [delegate inputBW];
        NSLog(@"checkinput: %d\n", result);
        [self _mono_newInputDone: result];
        // XXXX save result, if running
        [self performSelector:@selector(_mono_pollInput) withObject: nil afterDelay: (NSTimeInterval)0.001];
    }
}

- (void)_mono_showNewData
{
    @synchronized(self) {
        if (delegate && [delegate respondsToSelector:@selector(newBWOutput:)]) {
            [delegate newBWOutput: currentColorIsWhite];
            [collector recordTransmission: currentColorIsWhite?@"white":@"black" at: [collector now]];
        }
    }
}

@end
