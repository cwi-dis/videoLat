//
//  OutputView.m
//  macMeasurements
//
//  Created by Jack Jansen on 01-09-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "VideoOutputView.h"
#import <CoreServices/CoreServices.h>
#import <ApplicationServices/ApplicationServices.h>
#import <IOKit/graphics/IOGraphicsLib.h>


@implementation VideoOutputView

@synthesize mirrored;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
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
	if (VL_DEBUG) NSLog(@"Names %@", names);
    if([names count])
		rv = [names objectForKey:[[names allKeys] objectAtIndex:0]];
    return rv;
}

- (void)viewWillDraw
{
	NSScreen *curScreen = [[self window] screen];
	if (curScreen != self.oldScreen) {
		self.oldScreen = curScreen;
		if (self.bOutputName)
			[self.bOutputName setStringValue: self.deviceName];
	}
}

- (IBAction)toggleFullscreen: (NSMenuItem*)sender
{
    NSInteger state = [sender state];
    state = (state == NSOffState) ? NSOnState : NSOffState;
    if (VL_DEBUG) NSLog(@"Fullscreen now %d\n", (int)state);
    [sender setState: state];
    if (state == NSOnState) {
        [self enterFullScreenMode: [NSScreen mainScreen] withOptions:nil];
    } else {
        [self exitFullScreenModeWithOptions: nil];
    }
}

- (void)showNewData {
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    CIImage *newImage = [self.manager newOutputStart];
    assert(newImage);
    if (mirrored) {
        CIImage *mirror = [newImage imageByApplyingTransform: CGAffineTransformMakeScale(-1.0, 1.0)];
        newImage = mirror;
    }
    
    NSRect dstRect = [self bounds];
    CGFloat width = NSWidth(dstRect);
    CGFloat height = NSHeight(dstRect);
    width = height = ((width < height)? width : height);
    dstRect = NSMakeRect(NSMidX(dstRect)-width/2, NSMidY(dstRect)-height/2, width, height);
    [newImage drawInRect:dstRect fromRect:NSRectFromCGRect([newImage extent]) operation:NSCompositeCopy fraction:1];

    // Report back that we have displayed it.
    [self.manager newOutputDone];
}

@end
