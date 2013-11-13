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
    IBOutlet id<GraphDataProviderProtocol> source;
    NSColor *myColor;
}

- (void)drawRect:(NSRect)dirtyRect;

@end
