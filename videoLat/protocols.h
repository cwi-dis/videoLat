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

// Protocol for reporting changes to the settings
@protocol SettingsChangedProtocol
- (void)settingsChanged;
@end

// Protocol for an object that finds patterns in an input buffer
@protocol FindProtocol
@property(readonly) NSRect rect;
@property BOOL configuring;
- (char*) find: (void*)buffer width: (int)width height: (int)height format: (const char*)format size:(int)size;
@end

// Protocol for an object that creates patterns in an output buffer
@protocol GenProtocol
- (void) gen: (void*)buffer width: (int)width height: (int)height code: (const char *)code;
@end

// Protocol for an object that is responsible for displaying patterns
@protocol OutputViewProtocol
@property BOOL mirrored;
@property BOOL visible;
@property (readonly) NSString* deviceID;
@property (readonly) NSString* deviceName;
- (void) showNewData;
@end

// Protocol for a capturing object
@protocol DataCaptureProtocol
- (void) startCapturing;
- (void) stopCapturing;
@property (readonly) NSString* deviceID;
@property (readonly) NSString* deviceName;
@end

// Protocol for an object that is responsible for controlling a sequence of measurements
@protocol DataCollectorProtocol
- (uint64_t) now;
- (void) startCollecting: (NSString*)scenario input: (NSString*)inputId name: (NSString*)inputName output:(NSString*)outputId name: (NSString*)outputName;
- (void) stopCollecting;

- (void) recordTransmission: (NSString*)data at: (uint64_t)now;
- (void) recordReception: (NSString*)data at: (uint64_t)now;

- (void) output: (const char*)name event: (const char*)event data: (const char*)data start: (uint64_t)startTime;
- (void) output: (const char*)name event: (const char*)event data: (const char*)data;
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
@protocol MeasurementOutputManagerProtocol
- (CIImage *)newOutputStart;
- (void)newOutputDone;
- (void)updateOutputOverhead: (double)deltaT;
@end

// Protocol used by input data collector to report new data and timing.
@protocol MeasurementInputManagerProtocol
- (void)reportDataCapturer: (id)capturer;
- (void)setDetectionRect: (NSRect)theRect;
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
