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
- (void) showNewData;
@end

// Protocol for an object that is responsible for controlling dispay of a pattern
@protocol OutputProtocol
- (uint64_t) now;
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


#endif
