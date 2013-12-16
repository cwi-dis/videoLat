//
//  VideoMonoRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 25/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "VideoMonoRunManager.h"

@implementation VideoMonoRunManager

+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Monochrome Roundtrip"];
    [BaseRunManager registerNib: @"VideoMonoRunManager" forMeasurementType: @"Video Monochrome Roundtrip"];
}

- (VideoMonoRunManager*)init
{
    self = [super init];
    if (self) {
		blacklevel = 255;
		whitelevel = 0;
		nBWdetections = 0;
    }
    return self;
}

- (void) awakeFromNib
{
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
}

- (void) _mono_newInputDone: (bool)isWhite
{
	uint64_t receptionTime = [self.collector now];
    @synchronized(self) {
        assert(inputStartTime != 0);
        if (!self.running) return;
        
        if (isWhite == currentColorIsWhite) {
            // Found it! Invert for the next round
            currentColorIsWhite = !currentColorIsWhite;
            nBWdetections++;
            //xyzzy            status.bwString = [NSString stringWithFormat: @"found %d (current %s)", nBWdetections, isWhite?"white":"black"];
            [self.statusView update: self];
            // XXXJACK Is this correct? is "now" the best timestamp we have for the incoming hardware data?
            if (self.running)
				[self.collector recordReception: isWhite?@"white":@"black" at: receptionTime];
            inputAddedOverhead = 0;
            outputCode = [NSString stringWithFormat:@"%lld", receptionTime];
            [self performSelectorOnMainThread: @selector(_triggerNewOutputValue) withObject: nil waitUntilDone: NO];
            
        }
        inputStartTime = 0;
    }
}

- (void) newInputDone: (void*)buffer width: (int)w height: (int)h format: (const char*)formatStr size: (int)size
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
                if (self.running)
					[self.collector recordReception: foundColorIsWhite?@"white":@"black" at: inputStartTime-inputAddedOverhead];
				inputAddedOverhead = 0;
			}
			outputCode = [NSString stringWithFormat:@"%lld", [self.collector now]];
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
        if (self.delegate == nil || ![self.delegate hasInput]) return;
        [self newInputStart];
        bool result = [self.delegate inputBW];
        if (VL_DEBUG) NSLog(@"checkinput: %d\n", result);
        [self _mono_newInputDone: result];
        // XXXX save result, if running
        [self performSelector:@selector(_mono_pollInput) withObject: nil afterDelay: (NSTimeInterval)0.001];
    }
}

- (void)_mono_showNewData
{
    @synchronized(self) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(newBWOutput:)]) {
            [self.delegate newBWOutput: currentColorIsWhite];
			if (self.running)
				[self.collector recordTransmission: currentColorIsWhite?@"white":@"black" at: [self.collector now]];
        }
    }
}


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
        if (outputStartTime == 0) outputStartTime = [self.collector now];
        outputAddedOverhead = 0;
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
}

- (void) newOutputDone
{
    @synchronized(self) {
        if (outputStartTime == 0) return;
        assert(outputAddedOverhead < [self.collector now]);
        assert(strcmp([outputCode UTF8String], "BadCookie") != 0);
		uint64_t outputTime = [self.collector now] - outputAddedOverhead;
		if (self.running)
			[self.collector recordTransmission: currentColorIsWhite?@"white":@"black" at: outputTime];
        outputStartTime = 0;
        outputAddedOverhead = 0;
    }
}

- (void)_triggerNewOutputValue
{
	// XXXJACK can be simplified
	if (self.outputView.visible) {
		[self.outputView showNewData];
	} else {
		[self _mono_showNewData];
	}
}

#if 0

- (void)settingsChanged
{
    @synchronized(self) {
		if (self.outputView) {
			self.outputView.mirrored = settings.mirrorView;
			self.outputView.visible = settings.xmit;
		}
        if ([settings.coordHelper isEqualToString: @"None"]) {
			self.delegate = nil;
		} else {
			if (self.delegate && ![settings.coordHelper isEqualToString: [self.delegate script]]) {
				self.delegate = nil;
			}
            if (self.delegate == nil) {
                self.delegate = [[PythonSwitcher alloc] initWithScript: settings.coordHelper];
                if ([self.delegate hasInput]) {
                    [self performSelector: @selector(_mono_pollInput) withObject: nil afterDelay:(NSTimeInterval)0.001];
                }
			}
		}
        [self _triggerNewOutputValue];
    }
}
#endif

@end
