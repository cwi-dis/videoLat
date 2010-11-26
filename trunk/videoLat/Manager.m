//
//  OutputManager.m
//
//  Created by Jack Jansen on 27-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "Manager.h"
#import "PythonSwitcher.h"

@implementation Manager

- (bool) running
{
    return settings.running;
}

- (void) awakeFromNib 
{
    @synchronized(self) {
        [[settings window] setReleasedWhenClosed: false];
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
        
    //    output = [[Output alloc] init];
        genner = [[GenQRcodes alloc] init];
        finder = [[FindQRcodes alloc] init];
    }
}

- (void)settingsChanged
{
    @synchronized(self) {
        if (current_qrcode) {
            [current_qrcode release];
            current_qrcode = nil;
        }
        if (settings.runPython) {
            if (delegate == nil) 
                delegate = [[PythonSwitcher alloc] init];
        } else {
            if (delegate) [delegate release];
            delegate = nil;
        }
        NSWindow *w = nil;
        if (outputView) w = [outputView window];
        if (settings.xmit) {
            if (w && ![w isVisible])
                [w orderFront: self];
        } else {
            if (w) [w orderOut: self];
        }
#if 1
        // This does not work: hiding and re-showing the live video window
        // actually seems to create a new one. So then the outlet isn't
        // valid anymore.
        w = nil;
        if (inputView) w = [inputView window];
        if (settings.recv) {
            if (w && ![w isVisible])
                [w orderFront: self];
        } else {
            if (w) [w orderOut: self];
        }
#endif
        [outputView setNeedsDisplay: YES];
    }
}

- (CIImage *)newOutputStart
{
    @synchronized(self) {
        CIImage *newImage = nil;
        if (!settings.running || !settings.xmit) {
            newImage = [CIImage imageWithColor:[CIColor colorWithRed:0.9 green:0.9 blue:0.9]];
            CGRect rect = {0, 0, 480, 480};
            newImage = [newImage imageByCroppingToRect: rect];
            return newImage;
        }
#if 0
        assert(outputStartTime == 0);
        outputStartTime = [output now];
#else
        if (outputStartTime == 0) outputStartTime = [output now];
#endif
        outputAddedOverhead = 0;
    //    assert(settings.xmitBlackWhite || settings.xmitQRcode || settings.xmitAuto);
        if (settings.xmitBlackWhite) {
            // XXX Do black/white
            if (!settings.waitForDetection) {
                currentColorIsWhite = !currentColorIsWhite;
                [outputCode release];
                outputCode = [[NSString stringWithFormat:@"%lld", 
                    outputStartTime] retain];
                outputCodeHasBeenReported = false;
            }
            if (currentColorIsWhite) 
                newImage = [CIImage imageWithColor:[CIColor colorWithRed:1 green:1 blue:1]];
            else
                newImage = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]];
            CGRect rect = {0, 0, 480, 480};
            newImage = [newImage imageByCroppingToRect: rect];
            if (delegate && [delegate respondsToSelector:@selector(newBWOutput:)])
                [delegate newBWOutput: currentColorIsWhite];
            return newImage;
        }
        // We create a new image if either the previous one has been detected, or
        // if we are free-running.
        bool wantNewImage = (current_qrcode == NULL);
        if (!settings.waitForDetection) wantNewImage = true;
        
        if (!wantNewImage) {
            newImage = current_qrcode;
        } else {
            [outputCode release];
            outputCode = [[NSString stringWithFormat:@"%lld", outputStartTime] retain];
            assert(outputCodeHasBeenReported);
            outputCodeHasBeenReported = false;
            if (delegate && [delegate respondsToSelector:@selector(newOutput:)]) {
                NSString *new = [delegate newOutput: outputCode];
                if (new) {
                    // Delegate decided to wait for something else, we transmit black
                    newImage = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]];
                    CGRect rect = {0, 0, 480, 480};
                    newImage = [newImage imageByCroppingToRect: rect];
                    if (current_qrcode) [current_qrcode release];
                    current_qrcode = [newImage retain];
                    return newImage;
                }
            }
            char *bitmapdata = (char*)malloc(480*480*4);
            memset(bitmapdata, 0xf0, 480*480*4);
            [genner gen: bitmapdata width: 480 height: 480 code: [outputCode UTF8String]];
            NSData *data = [NSData dataWithBytesNoCopy:bitmapdata length:sizeof(bitmapdata) freeWhenDone: YES];
            CGSize size = {480, 480};
            newImage = [CIImage imageWithBitmapData:data bytesPerRow:4*480 size:size format: kCIFormatARGB8 colorSpace: nil];
            if (current_qrcode) [current_qrcode release];
            current_qrcode = [newImage retain];
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
        assert(outputAddedOverhead < [output now]);
        assert(strcmp([outputCode UTF8String], "BadCookie") != 0);
        if (settings.xmitQRcode) {
            [output output: "macVideoXmit" event: "generated" data: [outputCode UTF8String] start: [output now] - outputAddedOverhead];
        } else if (settings.xmitBlackWhite) {
            [output output: "blackWhiteXmit" event: currentColorIsWhite?"white":"black" data: [outputCode UTF8String] start: [output now] - outputAddedOverhead];
        }
        outputCodeHasBeenReported = true;
        outputStartTime = 0;
        outputAddedOverhead = 0;
        if (!settings.waitForDetection) {
            [outputView setNeedsDisplay: YES];
        }
    }
}

- (void) newInputStart
{
    @synchronized(self) {
//    assert(inputStartTime == 0);
        if (output) {
            inputStartTime = [output now];
            inputAddedOverhead = 0;
        }
    }
}

- (void) updateInputOverhead: (double) deltaT
{
    @synchronized(self) {
        if(inputStartTime != 0)
            inputAddedOverhead = (uint64_t)(deltaT*1000000.0);
    }
}

- (void) updateOutputOverhead: (double) deltaT
{
    @synchronized(self) {
        assert(deltaT < 1.0);
        if (outputStartTime != 0) {
            assert(outputAddedOverhead < [output now]);
            outputAddedOverhead = (uint64_t)(deltaT*1000000.0);
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
        assert(inputStartTime != 0);
        if (settings.running && settings.xmitBlackWhite) {
            // Wait for black/white, if possible
            NSRect area = settings.blackWhiteRect;
            if (NSIsEmptyRect(area)) {
                NSRunAlertPanel(
                    @"Alert",
                    @"Please detect at least one QRcode first to determine position.", 
                    nil, nil, nil);
                settings.recv = false;
                inputStartTime = 0;
                return;
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
                 NSRunAlertPanel(
                    @"Alert",
                    @"Black/White detection only implemented for greyscale capture, not \"%s\".", 
                    nil, nil, nil,
                    formatStr);
                settings.recv = false;
                inputStartTime = 0;
                return;
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
            int average = (total/count);
            //NSLog(@"Average greylevel is %d (black %d, white %d, #%d) want %s\n", average, blacklevel, whitelevel, nBWdetections, currentColorIsWhite?"white":"black");
            if (average < blacklevel) blacklevel = average;
            if (average > whitelevel) whitelevel = average;
            bool foundColorIsWhite = average > (whitelevel+blacklevel) / 2;
            if (foundColorIsWhite == currentColorIsWhite) {
                // Found it! Invert for the next round
                currentColorIsWhite = !currentColorIsWhite;
                nBWdetections++;
                settings.bwString = [[NSString stringWithFormat: @"found %d (levels %d..%d)", nBWdetections, blacklevel, whitelevel] retain];
                [settings updateButtonsIfNeeded];
                if (nBWdetections > 10) {
                    // The first 10 are for calibrating, then we get to business
                    [output output: "blackWhiteGrab" event: foundColorIsWhite?"white":"black" data: [outputCode UTF8String] start:inputStartTime-inputAddedOverhead];
                    inputAddedOverhead = 0;
                }
                [outputCode release];
                outputCode = [[NSString stringWithFormat:@"%lld", [output now]] retain];
                outputCodeHasBeenReported = false;
                [outputView setNeedsDisplay: YES];

            }
            inputStartTime = 0;
            return;
        }
                
            
        char *code = [finder find: buffer width: w height: h format: formatStr size:size];
        foundQRcode = (code != NULL);
        if (foundQRcode) {
            if (settings.waitForDetection) {
                // If we are in automatic mode, we compare the code to what was 
                // expected.
                if (strcmp(code, [outputCode UTF8String]) == 0) {
                    // outputStartTime = 0;
                    // Correct. Prepare for creating a new QRcode.
                    [outputView setNeedsDisplay: YES];
                    if (current_qrcode == nil) {
                        // We found the last one already, don't count it again.
                        return;
                    }
                    [current_qrcode release];
                    current_qrcode = nil;
                    if (lastOutputCode) [lastOutputCode release];
                    lastOutputCode = outputCode;
                    assert(outputCodeHasBeenReported);
                    outputCode = [[NSString stringWithFormat: @"BadCookie"] retain];
                } else if (strcmp(code, [lastOutputCode UTF8String]) == 0) {
                    // We have received the previous code again. Ignore.
                    NSLog(@"Same old code again: %s", code);
                } else {
                    // We have transmitted a code, but received a different one??
                    NSLog(@"Bad data: expected %@, got %s", outputCode, code);
                    NSString *baddata = [NSString stringWithFormat: @"%s-wanted-%@", code, outputCode];
                    [output output: "macVideoGrab" event: "baddata" data: [baddata UTF8String] start: inputStartTime-inputAddedOverhead];
                    inputAddedOverhead = 0;
                    inputStartTime = 0;
                    [outputView setNeedsDisplay: YES];
                    return;
                }
            } else {
                NSLog(@"Not waiting\n");
            }
            if (!lastInputCode || strcmp(code, [lastInputCode UTF8String]) != 0) {
                found_ok++;
                found_total++;
                [output output: "macVideoGrab" event: "data" data: code start: inputStartTime-inputAddedOverhead];
                [lastInputCode release];
                lastInputCode = [[NSString stringWithUTF8String: code] retain];
            }
            inputAddedOverhead = 0;
            // Remember rectangle (for black/white detection)
            settings.blackWhiteRect = finder.rect;
            [outputView setNeedsDisplay: YES];
        } else {
            found_total++;
            [output output: "macVideoGrab" event: "nodata" data: "none" start: inputStartTime-inputAddedOverhead];
            inputAddedOverhead = 0;
        }
        inputStartTime = 0;
        settings.detectString = [[NSString stringWithFormat: @" %d of %d", found_ok, found_total] retain];
        [settings updateButtonsIfNeeded];
    }
}
@end
