//
//  GraphView.h
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"

@interface GraphView : NSView {
}
@property(retain) NSColor *color;
@property(retain) IBOutlet NSTextField *bMaxX;
@property(retain) IBOutlet NSTextField *bMaxY;
@property(retain) IBOutlet id<GraphDataProviderProtocol> source;
@property(retain) NSNumber *maxXscale;
@property(retain) NSNumber *maxYscale;
@property(retain) NSString *maxXformat;
@property(retain) NSString *maxYformat;

- (void)drawRect:(NSRect)dirtyRect;

@end
