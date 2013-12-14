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
#define VIDEOLAT_FILE_VERSION @"0.4"

// Global debug stuff
#define VL_DEBUG 0

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
@protocol OutputVideoViewProtocol
@property (readonly) NSString* deviceID;
@property (readonly) NSString* deviceName;
- (void) showNewData;
@end

// Protocol for a capturing object
@protocol InputCaptureProtocol
- (void) startCapturing: (BOOL)showPreview;
- (void) stopCapturing;
@property (readonly) NSString* deviceID;
@property (readonly) NSString* deviceName;
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

// Protocol for an object that influences what patterns the manager generates
// XXX Needs to go...
@protocol ManagerDelegateProtocol <NSObject>
@property(readonly) NSString *script;
@property(readonly) bool hasInput;
- (NSString*)newOutput: (NSString*)data;
- (void)newBWOutput: (bool)isWhite;
- (bool)inputBW;
@end

// Protocol used by output view to request new data and report results
@protocol RunOutputManagerProtocol
- (CIImage *)newOutputStart;
- (void)newOutputDone;
- (void)updateOutputOverhead: (double)deltaT;
@end

// Protocol used by input data collector to report new data and timing.
@protocol RunInputManagerProtocol
- (void)reportDataCapturer: (id)capturer;
- (void)setFinderRect: (NSRect)theRect;
- (void)newInputStart;
- (void)updateInputOverhead: (double)deltaT;
- (void)newInputDone;
- (void) newInputDone: (void*)buffer
    width: (int)w
    height: (int)h
    format: (const char*)formatStr
    size: (int)size;
@end
#endif
