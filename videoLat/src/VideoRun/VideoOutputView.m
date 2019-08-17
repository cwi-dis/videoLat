//
//  OutputView.m
//  macMeasurements
//
//  Created by Jack Jansen on 01-09-10.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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

- (void)awakeFromNib
{
    [super awakeFromNib];
    assert(self.manager);
}

- (BOOL)available {
    return YES;
}

- (void)stop {
}

#ifdef WITH_APPKIT
//
// Returns the io_service_t corresponding to a CG display ID, or 0 on failure.
// The io_service_t should be released with IOObjectRelease when not needed.
//
// This function was grabbed from github.com/glfw/glfw, and it has pretty much the same
// functionality as the CGDisplayIOServicePort() function that Apple deprecated in 10.9.
//
static io_service_t IOServicePortFromCGDisplayID(CGDirectDisplayID displayID)
{
    io_iterator_t iter;
    io_service_t serv, servicePort = 0;
    
    CFMutableDictionaryRef matching = IOServiceMatching("IODisplayConnect");
    
    // releases matching for us
    kern_return_t err = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                     matching,
                                                     &iter);
    if (err)
    {
        return 0;
    }
    
    while ((serv = IOIteratorNext(iter)) != 0)
    {
        CFDictionaryRef info;
        CFIndex vendorID, productID;
        CFNumberRef vendorIDRef, productIDRef;
        Boolean success;
        
        info = IODisplayCreateInfoDictionary(serv,
                                             kIODisplayOnlyPreferredName);
        
        vendorIDRef = CFDictionaryGetValue(info,
                                           CFSTR(kDisplayVendorID));
        productIDRef = CFDictionaryGetValue(info,
                                            CFSTR(kDisplayProductID));
        
        success = CFNumberGetValue(vendorIDRef, kCFNumberCFIndexType,
                                   &vendorID);
        success &= CFNumberGetValue(productIDRef, kCFNumberCFIndexType,
                                    &productID);
        
        if (!success)
        {
            CFRelease(info);
            continue;
        }
        
        if (CGDisplayVendorNumber(displayID) != vendorID ||
            CGDisplayModelNumber(displayID) != productID)
        {
            CFRelease(info);
            continue;
        }
        
        // we're a match
        servicePort = serv;
        CFRelease(info);
        break;
    }
    
    IOObjectRelease(iter);
    return servicePort;
}

#endif
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
        io_service_t displayPort = IOServicePortFromCGDisplayID(aID);
        NSDictionary *dict = (NSDictionary *)CFBridgingRelease(IODisplayCreateInfoDictionary(displayPort, 0));
        NSDictionary *names = [dict objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
        if (VL_DEBUG) NSLog(@"Names %@", names);
        NSString *thisName;
        if([names count]) {
            thisName = [names objectForKey:@"en_US"];
            if (thisName == nil) {
                thisName = [names objectForKey:[[names allKeys] objectAtIndex:0]];
            }
        }
        if(thisName)
            [rv addObject: thisName];
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
    io_service_t displayPort = IOServicePortFromCGDisplayID(aID);
    NSDictionary *dict = (NSDictionary *)CFBridgingRelease(IODisplayCreateInfoDictionary(displayPort, 0));
    NSDictionary *names = [dict objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
	if (1 || VL_DEBUG) NSLog(@"Names %@", names);
    if([names count]) {
        rv = [names objectForKey:@"en_US"];
        if (rv == nil) {
            rv = [names objectForKey:[[names allKeys] objectAtIndex:0]];
        }
    }
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
    CIImage *newImage = [self.manager getNewOutputImage];
    assert(newImage);
    
    NSorUIRect dstRect = [self bounds];
    CGFloat width = NSorUIWidth(dstRect);
    CGFloat height = NSorUIHeight(dstRect);
    width = height = ((width < height)? width : height);
    dstRect = NSorUIMakeRect(NSorUIMidX(dstRect)-width/2, NSorUIMidY(dstRect)-height/2, width, height);
#ifdef WITH_UIKIT
    UIImage *drawImage = [UIImage imageWithCIImage: newImage];
    [drawImage drawInRect:dstRect];
#else
    [newImage drawInRect:dstRect fromRect:NSRectFromCGRect([newImage extent]) operation:NSCompositingOperationCopy fraction:1];
#endif

    // Report back that we have displayed it.
    [self.manager newOutputDone];
}

@end
