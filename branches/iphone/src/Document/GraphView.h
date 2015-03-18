///
///  @file GraphView.h
///  @brief Defines the GraphView object.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "protocols.h"

///
/// Show a simple graphical representation of an ordered set of numbers.
/// The numbers are provided by something that adheres to the GraphDataProviderProtocol,
/// currently either a MeasurementDataStore or a MeasurementDistribution for one of those.
/// 
@interface GraphView
#ifdef WITH_UIKIT
: UIView
#else
: NSView
#endif
{
}
#ifdef WITH_UIKIT
@property(weak) IBOutlet UILabel *bMinX;    //!< UI element assigned by NIB, shows minimum X value
@property(weak) IBOutlet UILabel *bMaxX;    //!< UI element assigned by NIB, shows maximum X value
@property(weak) IBOutlet UILabel *bMinY;    //!< UI element assigned by NIB, shows minimum Y value
@property(weak) IBOutlet UILabel *bMaxY;    //!< UI element assigned by NIB, shows maximum Y value
#else
@property(weak) IBOutlet NSTextField *bMinX;    //!< UI element assigned by NIB, shows minimum X value
@property(weak) IBOutlet NSTextField *bMaxX;    //!< UI element assigned by NIB, shows maximum X value
@property(weak) IBOutlet NSTextField *bMinY;    //!< UI element assigned by NIB, shows minimum Y value
@property(weak) IBOutlet NSTextField *bMaxY;    //!< UI element assigned by NIB, shows maximum Y value
#endif
@property(weak) IBOutlet NSObject<GraphDataProviderProtocol> *modelObject;  //!< Assigned by NIB, the source of the data this view displays
@property(strong) NSorUIColor *color;               //!< Allows owner to set graph color
@property(strong) NSNumber *xLabelScaleFactor;          //!< Allows owner to override X data units per pixel
@property(strong) NSNumber *yLabelScaleFactor;          //!< Allows owner to override Y data units per pixel
@property(strong) NSString *xLabelFormat;         //!< Allows owner to override printf-style format for bMaxX
@property(strong) NSString *yLabelFormat;         //!< Allows owner to override printf-style format for bMaxY
@property BOOL showAverage;                     //!< View shows the average Y as a line when true
@property BOOL showNormal;                      //!< View shows normal distribution as a curve when true

- (void)drawRect:(NSorUIRect)dirtyRect;             //!< Callback routine to draw the view

@end
