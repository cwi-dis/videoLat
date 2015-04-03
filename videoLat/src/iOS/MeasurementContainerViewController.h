//
//  MeasurementContainerViewController.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "protocols.h"
#import "MeasurementDataStore.h"
#import "BaseRunManager.h"

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
