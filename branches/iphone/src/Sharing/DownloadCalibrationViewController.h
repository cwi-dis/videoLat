//
//  DownloadSelectionView.h
//  videoLat
//
//  Created by Jack Jansen on 08/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"

@interface DownloadCalibrationViewController : NSViewController<NewMeasurementDelegate, DownloadQueryDelegate> {
    NSArray *calibrations;
}

@property(weak) IBOutlet NSPopUpButton *bCalibrations;

- (IBAction) doDownload: (id)sender;
- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *)dataStore;
- (void)availableCalibrations: (NSArray *)allCalibrations;

- (void)_updateCalibrations;
- (void)_downloadCalibration: (NSDictionary *)calibration;
- (void)_listCalibrations;
@end
