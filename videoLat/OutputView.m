//
//  OutputView.m
//  macMeasurements
//
//  Created by Jack Jansen on 01-09-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "OutputView.h"
#import <CoreServices/CoreServices.h>
#import <ApplicationServices/ApplicationServices.h>

// Screen refresh callback (plain C)

static void
MyScreenRefreshCallback(CGRectCount count, const CGRect *rects, void *userArg)
{
	OutputView *itself = (OutputView *)userArg;
	assert(itself);
	assert(count);
	[itself refreshCallback: count rects: rects];
}


@implementation OutputView

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
	CGRegisterScreenRefreshCallback(MyScreenRefreshCallback, (void *)self);
}

- (IBAction)toggleFullscreen: (NSMenuItem*)sender
{
    NSInteger state = [sender state];
    state = (state == NSOffState) ? NSOnState : NSOffState;
    NSLog(@"Fullscreen now %d\n", state);
    [sender setState: state];
    if (state == NSOnState) {
        [self enterFullScreenMode: [NSScreen mainScreen] withOptions:nil];
    } else {
        [self exitFullScreenModeWithOptions: nil];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
    //NSLog(@"outputView willDisplayImage\n");
    CIImage *newImage = [manager newOutputStart];
    assert(newImage);
    if (settings.mirrorView) {
        newImage = [newImage imageByApplyingTransform: CGAffineTransformMakeScale(-1.0, 1.0)];
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
}


- (void)refreshCallback: (CGRectCount)count rects: (const CGRect *)rectArray
{
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
}

@end
