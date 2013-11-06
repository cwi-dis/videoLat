//
//  protocols.h
//  videoLat
//
//  Created by Jack Jansen on 06/11/13.
//
//

#ifndef videoLat_protocols_h
#define videoLat_protocols_h

@protocol FindProtocol
@property(readonly) NSRect rect;
@property BOOL configuring;
- (char*) find: (void*)buffer width: (int)width height: (int)height format: (const char*)format size:(int)size;
@end

@protocol GenProtocol
- (void) gen: (void*)buffer width: (int)width height: (int)height code: (const char *)code;
@end

#endif
