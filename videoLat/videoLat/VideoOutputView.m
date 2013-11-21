//
//  OutputView.m
//  macMeasurements
//
//  Created by Jack Jansen on 01-09-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "VideoOutputView.h"
#import <CoreServices/CoreServices.h>
#import <ApplicationServices/ApplicationServices.h>
#import <IOKit/graphics/IOGraphicsLib.h>

// Screen refresh callback (plain C)

// This define seems to cause more trouble than it's worth. The intention was
// to wait with generating the "data transmitted" message until the vertical retrace.
// but sometimes the data is captured before that.
#undef XMIT_TIME_AT_RETRACE_TIME

#ifdef XMIT_TIME_AT_RETRACE_TIME
static void
MyScreenRefreshCallback(CGRectCount count, const CGRect *rects, void *userArg)
{
	OutputView *itself = (OutputView *)userArg;
	assert(itself);
	assert(count);
	[itself refreshCallback: count rects: rects];
}
#endif // XMIT_TIME_AT_RETRACE_TIME

@implementation VideoOutputView

@synthesize mirrored;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        newOutputDone = false;
    }
    return self;
}


- (void) awakeFromNib 
{
#ifdef XMIT_TIME_AT_RETRACE_TIME
	CGRegisterScreenRefreshCallback(MyScreenRefreshCallback, (void *)self);
#endif
    [[self window] setReleasedWhenClosed: false];

}

- (NSString *)deviceID
{
	NSWindow *window = [self window];
	NSScreen *screen = [window screen];
	NSDictionary *screenDescription = [screen deviceDescription];
	NSNumber *screenNumber = [screenDescription objectForKey:@"NSScreenNumber"];
	return [screenNumber stringValue];
}

- (NSString *)deviceName
{
	NSString *rv = @"Unknown";
	NSWindow *window = [self window];
	NSScreen *screen = [window screen];
	NSDictionary *screenDescription = [screen deviceDescription];
	NSNumber *screenNumber = [screenDescription objectForKey:@"NSScreenNumber"];
    CGDirectDisplayID aID = [screenNumber unsignedIntValue];
    io_service_t displayPort = CGDisplayIOServicePort(aID);
    NSDictionary *dict = (NSDictionary *)CFBridgingRelease(IODisplayCreateInfoDictionary(displayPort, 0));
    NSDictionary *names = [dict objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
	NSLog(@"Names %@", names);
    if([names count])
		rv = [names objectForKey:[[names allKeys] objectAtIndex:0]];
    return rv;
}

- (IBAction)toggleFullscreen: (NSMenuItem*)sender
{
    NSInteger state = [sender state];
    state = (state == NSOffState) ? NSOnState : NSOffState;
    NSLog(@"Fullscreen now %d\n", (int)state);
    [sender setState: state];
    if (state == NSOnState) {
        [self enterFullScreenMode: [NSScreen mainScreen] withOptions:nil];
    } else {
        [self exitFullScreenModeWithOptions: nil];
    }
}

- (BOOL)visible
{
	// XXX Is this correct???
	NSWindow *w = self.window;
	if (w == nil) return FALSE;
	return [w isVisible];
}

- (void)setVisible:(BOOL)visible
{
	NSWindow *w = self.window;
	if (w == nil) return;
	if (visible) {
		[w orderFront: self];
	} else {
		[w orderOut: self];
	}
}

- (void)showNewData {
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
    //NSLog(@"outputView willDisplayImage\n");
    CIImage *newImage = [manager newOutputStart];
    assert(newImage);
    if (mirrored) {
        CIImage *mirror = [newImage imageByApplyingTransform: CGAffineTransformMakeScale(-1.0, 1.0)];
        newImage = mirror;
    }
	// We do not output our log message immedeately, we wait for the next refresh.
    // xxx draw newImage
	newOutputDone = true;
    NSRect dstRect = [self bounds];
    CGFloat width = NSWidth(dstRect);
    CGFloat height = NSHeight(dstRect);
    width = height = ((width < height)? width : height)/* - 60*/;
    dstRect = NSMakeRect(NSMidX(dstRect)-width/2, NSMidY(dstRect)-height/2, width, height);
    [newImage drawInRect:dstRect fromRect:NSRectFromCGRect([newImage extent]) operation:NSCompositeCopy fraction:1];
#ifndef XMIT_TIME_AT_RETRACE_TIME
    [manager newOutputDone];
#endif
}


- (void)refreshCallback: (CGRectCount)count rects: (const CGRect *)rectArray
{
#ifndef XMIT_TIME_AT_RETRACE_TIME
    assert(0);
#else
	if (!newOutputDone) return;
	// Our window rectangle is in AppKit coordinates (lowerleft of main screen is 0,0),
	// but CG coordinates use topleft of main screen is 0,0.
	NSRect frame = [[self window] frame];
	NSRect mainScreenFrame = [[NSScreen mainScreen] frame];
	// Convert from bottomleft origin to topleft origin
	CGRect ourRect = NSRectToCGRect(frame);
	ourRect.origin.y = mainScreenFrame.size.height - (frame.size.height + frame.origin.y);
	while (count--) {
		if (CGRectIntersectsRect(ourRect, *rectArray)) {
			//NSLog(@"Did redraw for our output window\n");
			newOutputDone = false;
			// Find how much longer until the beam retraces
#if 0
            // Always assume main display
			CGDirectDisplayID display = CGMainDisplayID();
#else
            // Use display that has upperleft pixel of our rect
            CGDirectDisplayID display;
            uint32_t count;
            CGError err = CGGetDisplaysWithPoint(ourRect.origin, 1, &display, &count);
            assert(err == 0);
            if(count == 0) return;
#endif
			CGDisplayModeRef mode = CGDisplayCopyDisplayMode(display);
			double rate = CGDisplayModeGetRefreshRate(mode);
            if (rate > 0) {
                size_t height = CGDisplayModeGetHeight(mode);
                uint32_t beamPos = CGDisplayBeamPosition(display);
				if (beamPos < height) {
					double delayUntilRetrace = (double)(height-beamPos)/(height*rate);
					[manager updateOutputOverhead: delayUntilRetrace];
				}
            }
			CGDisplayModeRelease(mode);
		    [manager newOutputDone];
			return;
		}
		rectArray++;
	}
#endif // XMIT_TIME_AT_RETRACE_TIME
}

@end
