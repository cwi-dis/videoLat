//
//  MeasurementRunView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Cocoa/Cocoa.h>

///
/// An NSView that shows information such as number of detections and average delay
/// while a measurement run is underway.
///
@interface RunStatusView : NSView
@property(weak) IBOutlet NSButton *bStop;		//!< Initialized in the NIB: reference to the stop button.

@property(weak) IBOutlet NSTextField *bCount;	//!< Initialized in the NIB: reference to the count text field.
@property(weak) IBOutlet NSTextField *bAverage;	//!< Initialized in the NIB: reference to the average delay text field.

@property(strong) NSString *detectCount;		//!< Run Manager stores count value here
@property(strong) NSString *detectAverage;		//!< Run manager stores average value here

- (IBAction)update: (id)sender;					//!< Called by Run manager after updating detectCount or detectAverage.
@end
