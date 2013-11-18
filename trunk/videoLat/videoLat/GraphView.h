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
    NSColor *myColor;
}
@property(retain) IBOutlet NSTextField *bMaxX;
@property(retain) IBOutlet NSTextField *bMaxY;
@property(retain) IBOutlet id<GraphDataProviderProtocol> source;

- (void)drawRect:(NSRect)dirtyRect;

@end
