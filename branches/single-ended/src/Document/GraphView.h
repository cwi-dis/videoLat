///
///  @file GraphView.h
///  @brief Defines the GraphView object.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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
@property(strong) NSColor *color;               //!< Allows owner to set graph color
@property(weak) IBOutlet NSTextField *bMaxX;    //!< UI element assigned by NIB, shows maximum X value
@property(weak) IBOutlet NSTextField *bMaxY;    //!< UI element assigned by NIB, shows maximum Y value
@property(weak) IBOutlet id<GraphDataProviderProtocol> source;  //!< Assigned by NIB, the source of the data this view displays
@property(strong) NSNumber *maxXscale;          //!< Allows owner to override X data units per pixel
@property(strong) NSNumber *maxYscale;          //!< Allows owner to override Y data units per pixel
@property(strong) NSString *maxXformat;         //!< Allows owner to override printf-style format for bMaxX
@property(strong) NSString *maxYformat;         //!< Allows owner to override printf-style format for bMaxY
@property BOOL showAverage;                     //!< View shows the average Y as a line when true
@property BOOL showNormal;                      //!< View shows normal distribution as a curve when true

- (void)drawRect:(NSRect)dirtyRect;             //!< Callback routine to draw the view

@end
