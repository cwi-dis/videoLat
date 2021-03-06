///
///  @file MeasurementContainerViewController.h
///  @brief Holds definition of MeasurementContainerViewController object (iOS only).
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <UIKit/UIKit.h>
#import "protocols.h"
#import "MeasurementDataStore.h"
#import "BaseRunManager.h"

///
/// View Controller for holding the XIB that does the measurement.
///
@interface MeasurementContainerViewController : UIViewController<NewMeasurementDelegate> {
	NSArray *measurementNibObjects;				//!< Storage for view-nib toplevel objects
	MeasurementDataStore *finishedDataStore;	//!< Internal, remembers datastore while segue is in progress
}

@property(strong) NSString *measurementTypeName;	//!< Communicated by InputSelectionViewController
@property(strong) NSString *inputDeviceName;	//!< Communicated by InputSelectionViewController
@property(strong) NSString *baseMeasurementName;	//!< Communicated by InputSelectionViewController
@property(strong) IBOutlet UIView *measurementView;	//!< Set by NIB
@property(strong) IBOutlet BaseRunManager *runManager;	//!< Set by NIB

- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *)dataStore;

@end
