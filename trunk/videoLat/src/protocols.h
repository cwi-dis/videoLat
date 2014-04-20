//
//  protocols.h
//  videoLat
//
//  Created by Jack Jansen on 06/11/13.
//
//

#ifndef videoLat_protocols_h
#define videoLat_protocols_h

#import <Cocoa/Cocoa.h>

// This constant needs to go somewhere...
#define VIDEOLAT_FILE_VERSION @"0.5"

// Global debug stuff
#define VL_DEBUG 0

// Protocol for an object that provides time values (in microseconds)
@protocol ClockProtocol
- (uint64_t)now;
@end

// Protocol for an object that finds patterns in an input buffer
@protocol InputVideoFindProtocol
@property(readonly) NSRect rect;
@property BOOL configuring;
- (char*) find: (void*)buffer width: (int)width height: (int)height format: (const char*)format size:(int)size;
@end

// Protocol for an object that creates patterns in an output buffer
@protocol OutputVideoGenProtocol
- (void) gen: (void*)buffer width: (int)width height: (int)height code: (const char *)code;
@end

// Protocol for an object that is responsible for displaying patterns
@protocol OutputViewProtocol
@property (readonly) NSString* deviceID;
@property (readonly) NSString* deviceName;
@property BOOL mirrored;
- (void) showNewData;
@end

// Protocol for a capturing object
@protocol InputCaptureProtocol
- (void) startCapturing: (BOOL)showPreview;
- (void) stopCapturing;
- (void) stop;
@property (readonly) NSString* deviceID;
@property (readonly) NSString* deviceName;
@end

// Protocol for a binary (monochrome) hardware input/output device
@protocol HardwareLightProtocol
- (BOOL)available;
- (double)light: (double)level;
@property (readonly) NSString* deviceID;
@property (readonly) NSString* deviceName;
@property (readonly) NSString* lastErrorMessage;
@end

// Protocol for an object that can provide data to a GraphView
@protocol GraphDataProviderProtocol
@property(readonly) double min;
@property(readonly) double max;
@property(readonly) int count;
@property(readonly) double average;
@property(readonly) double stddev;
@property(readonly) double maxXaxis;

- (NSNumber *)valueForIndex: (int) i;
@end

// Protocol used by output view to request new data and report results
@protocol RunOutputManagerProtocol
- (CIImage *)newOutputStart;
- (void)newOutputDone;
@end

// Protocol used by input data collector to report new data and timing.
@protocol RunInputManagerProtocol
- (void)restart;
- (void)setFinderRect: (NSRect)theRect;
- (void)newInputStart;
- (void)newInputStart:(uint64_t)timestamp;
- (void)newInputDone;
- (void) newInputDone: (void*)buffer
    width: (int)w
    height: (int)h
    format: (const char*)formatStr
    size: (int)size;
- (void)newInputDone: (void*)buffer
    size: (int)size
    channels: (int)channels
    at: (uint64_t)timestamp;
@end
#endif
