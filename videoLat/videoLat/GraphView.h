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
@property(strong) NSColor *color;
@property(weak) IBOutlet NSTextField *bMaxX;
@property(weak) IBOutlet NSTextField *bMaxY;
@property(weak) IBOutlet id<GraphDataProviderProtocol> source;
@property(strong) NSNumber *maxXscale;
@property(strong) NSNumber *maxYscale;
@property(strong) NSString *maxXformat;
@property(strong) NSString *maxYformat;
@property BOOL showAverage;
@property BOOL showNormal;

- (void)drawRect:(NSRect)dirtyRect;

@end
