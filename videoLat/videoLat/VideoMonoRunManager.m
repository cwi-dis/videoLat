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
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Mono Roundtrip"];
    [BaseRunManager registerNib: @"VideoMonoRunManager" forMeasurementType: @"Video Mono Roundtrip"];
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Camera Input Calibrate"];
    [BaseRunManager registerNib: @"HardwareToCameraRunManager" forMeasurementType: @"Camera Input Calibrate"];
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
    sensitiveArea = NSMakeRect(160, 120, 320, 240);
}

- (void) newInputDone: (void*)buffer width: (int)w height: (int)h format: (const char*)formatStr size: (int)size
{
    @synchronized(self) {
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
            NSLog(@"Unexpected newInputDone format %s", formatStr);
            return;
		}
        if (outputCode == nil) return;
        
		int minx, x, maxx, miny, y, maxy, ystep;
		minx = sensitiveArea.origin.x + (sensitiveArea.size.width/4);
		maxx = minx + (sensitiveArea.size.width/2);
		miny = sensitiveArea.origin.y + (sensitiveArea.size.height/4);
		maxy = miny + (sensitiveArea.size.width/2);
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
			// Found expected color.
            if (self.running) {
                [self.collector recordReception: outputCode at: inputStartTime];
            } else if (self.preRunning) {
                [self _prerunRecordReception: outputCode];
            }
			[self _triggerNewOutputValue];
        } else {
            if (self.preRunning) {
                [self _prerunRecordNoReception];
            }
            
		}
		inputStartTime = 0;
        if (self.running) {
            self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
            self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
            [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
        }
	}
}


- (CIImage *)newOutputStart
{
    @synchronized(self) {
        CIImage *newImage = nil;
        if (!self.running && !self.preRunning) {
            newImage = [CIImage imageWithColor:[CIColor colorWithRed:0.1 green:0.4 blue:0.5]];
            CGRect rect = {0, 0, 480, 480};
            newImage = [newImage imageByCroppingToRect: rect];
            return newImage;
        }
        outputStartTime = [self.clock now];
        prerunOutputStartTime = outputStartTime;
		if (currentColorIsWhite) {
			newImage = [CIImage imageWithColor:[CIColor colorWithRed:1 green:1 blue:1]];
            outputCode = @"white";
		} else {
			newImage = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]];
            outputCode = @"black";
        }
		CGRect rect = {0, 0, 480, 480};
		newImage = [newImage imageByCroppingToRect: rect];
		return newImage;
    }
}

- (void)_triggerNewOutputValue
{
    currentColorIsWhite = !currentColorIsWhite;
	prerunOutputStartTime = 0;
	outputStartTime = 0;
	inputStartTime = 0;
    outputCode = nil;
	[self.outputView performSelectorOnMainThread:@selector(showNewData) withObject:nil waitUntilDone:NO ];
}

#if 0

- (void) _mono_newInputDone: (bool)isWhite
{
	uint64_t receptionTime = [self.clock now];
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
            outputCode = [NSString stringWithFormat:@"%lld", receptionTime];
            [self _triggerNewOutputValue];
            
        }
        inputStartTime = 0;
    }
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
				[self.collector recordTransmission: currentColorIsWhite?@"white":@"black" at: [self.clock now]];
        }
    }
}

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
