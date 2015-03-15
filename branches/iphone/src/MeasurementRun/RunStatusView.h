///
///  @file RunStatusView.h
///  @brief Defines RunStatusView object.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "protocols.h"

///
/// An NSView that shows information such as number of detections and average delay
/// while a measurement run is underway.
/// This view usually lives together with RunTypeView, and is instantiated from
/// the NewMeasurement.xib NIB file.
///
@interface RunStatusView : NSorUIView
@property(weak) IBOutlet NSorUIButton *bStop;		//!< Initialized in the NIB: reference to the stop button.

@property(weak) IBOutlet NSorUITextField *bCount;	//!< Initialized in the NIB: reference to the count text field.
@property(weak) IBOutlet NSorUITextField *bAverage;	//!< Initialized in the NIB: reference to the average delay text field.

@property(strong) NSString *detectCount;		//!< Run Manager stores count value here
@property(strong) NSString *detectAverage;		//!< Run manager stores average value here

- (IBAction)update: (id)sender;					//!< Called by Run manager after updating detectCount or detectAverage.
@end
