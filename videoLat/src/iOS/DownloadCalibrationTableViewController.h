///
///  @file DownloadCalibrationTableViewController.h
///  @brief Holds definition of DownloadCalibrationViewController object (iOS only).
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <UIKit/UIKit.h>
#import "protocols.h"

///
/// Object that handles downloading calibrations from videolat.org.
///
@interface DownloadCalibrationTableViewController : UITableViewController<NewMeasurementDelegate, DownloadQueryDelegate>
{
    NSArray *calibrations;
    BOOL searching;
	MeasurementDataStore *downloadedDataStore;
}

- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *)dataStore;
- (void)availableCalibrations: (NSArray *)allCalibrations;

- (void)_updateCalibrations;
- (void)_downloadCalibration: (NSDictionary *)calibration;
- (void)_listCalibrations;

@end
