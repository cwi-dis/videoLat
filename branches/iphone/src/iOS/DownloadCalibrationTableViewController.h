//
//  DownloadCalibrationTableViewController.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 13/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "protocols.h"

@interface DownloadCalibrationTableViewController : UITableViewController<DownloadDelegate, DownloadQueryDelegate> {
    NSArray *calibrations;
    BOOL searching;
}

- (IBAction) doDownload: (id)sender;
- (void)didDownload: (MeasurementDataStore *)dataStore;
- (void)availableCalibrations: (NSArray *)allCalibrations;

- (void)_updateCalibrations;
- (void)_downloadCalibration: (NSDictionary *)calibration;
- (void)_listCalibrations;

@end
