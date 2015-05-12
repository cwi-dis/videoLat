///
///  @file NewCalibrationTableViewController.h
///  @brief Holds definition of NewCalibrationTableViewController object.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "NewMeasurementTableViewController.h"

///
/// Subclass of NewMeasurementTableViewController that handles initiating a new calibration measurement.
///
@interface NewCalibrationTableViewController : NewMeasurementTableViewController

- (NSArray *)measurementNames;
@end
