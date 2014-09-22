//
//  GraphView.h
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"

///
/// Show a simple graphical representation of an ordered set of numbers.
/// The numbers are provided by something that adheres to the GraphDataProviderProtocol,
/// currently either a MeasurementDataStore or a MeasurementDistribution for one of those.
/// 
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
