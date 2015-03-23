//
//  OutputView.m
//  macMeasurements
//
//  Created by Jack Jansen on 01-09-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "VideoOutputView.h"
#ifdef WITH_APPKIT
#import <CoreServices/CoreServices.h>
#import <ApplicationServices/ApplicationServices.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#endif

#ifdef WITH_UIKIT
#define NSRectfromCGRect(x) (x)
#endif

@implementation VideoOutputView

@synthesize mirrored;

+ (NSArray *) allDeviceTypeIDs
{
#ifdef WITH_APPKIT
    NSScreen *d;
    NSMutableArray *rv = [NSMutableArray arrayWithCapacity:128];
    NSArray *devs = [NSScreen screens];
    for(d in devs) {
        NSDictionary *screenDescription = [d deviceDescription];
        NSNumber *screenNumber = [screenDescription objectForKey:@"NSScreenNumber"];
        CGDirectDisplayID aID = [screenNumber unsignedIntValue];
        io_service_t displayPort = CGDisplayIOServicePort(aID);
        NSDictionary *dict = (NSDictionary *)CFBridgingRelease(IODisplayCreateInfoDictionary(displayPort, 0));
        NSDictionary *names = [dict objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
        if (VL_DEBUG) NSLog(@"Names %@", names);
        if([names count])
            [rv addObject: [names objectForKey:[[names allKeys] objectAtIndex:0]]];
    }
    return rv;
#else
	return @[ @"screen"];
#endif
}

- (id)initWithFrame:(NSorUIRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (NSString *)deviceID
{
#ifdef WITH_APPKIT
	NSWindow *window = [self window];
	NSScreen *screen = [window screen];
	NSDictionary *screenDescription = [screen deviceDescription];
	NSNumber *screenNumber = [screenDescription objectForKey:@"NSScreenNumber"];
	return [screenNumber stringValue];
#else
	return @"screen";
#endif
}

- (NSString *)deviceName
{
#ifdef WITH_APPKIT
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
#else
	return @"screen";
#endif
}

- (void)viewWillDraw
{
#ifdef WITH_APPKIT
	NSScreen *curScreen = [[self window] screen];
	if (curScreen != self.oldScreen) {
		self.oldScreen = curScreen;
		if (self.bOutputName)
			[self.bOutputName setStringValue: self.deviceName];
	}
#endif
}

- (void)showNewData {
#ifdef WITH_UIKIT
	[self setNeedsDisplay];
#else
	[self setNeedsDisplay:YES];
#endif
}

- (void)drawRect:(NSorUIRect)dirtyRect {
    CIImage *newImage = [self.manager newOutputStart];
    assert(newImage);
    if (mirrored) {
        CIImage *mirror = [newImage imageByApplyingTransform: CGAffineTransformMakeScale(-1.0, 1.0)];
        newImage = mirror;
    }
    
    NSorUIRect dstRect = [self bounds];
    CGFloat width = NSorUIWidth(dstRect);
    CGFloat height = NSorUIHeight(dstRect);
    width = height = ((width < height)? width : height);
    dstRect = NSorUIMakeRect(NSorUIMidX(dstRect)-width/2, NSorUIMidY(dstRect)-height/2, width, height);
#ifdef WITH_UIKIT
    UIImage *drawImage = [UIImage imageWithCIImage: newImage];
    [drawImage drawInRect:dstRect];
#else
    [newImage drawInRect:dstRect fromRect:NSRectFromCGRect([newImage extent]) operation:NSCompositeCopy fraction:1];
#endif

    // Report back that we have displayed it.
    [self.manager newOutputDone];
}

@end
