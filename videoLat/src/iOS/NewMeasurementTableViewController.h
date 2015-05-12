///
///  @file NewMeasurementTableViewController.h
///  @brief Holds definition of NewMeasurementTableViewController object (iOS only).
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <UIKit/UIKit.h>

///
/// Object that handles UI for selecting a new measurement type.
///
@interface NewMeasurementTableViewController : UITableViewController {
	NSString *selectedMeasurement;
}

- (NSArray *)measurementNames;
@end
