///
///  @file DownloadCalibrationViewController.h
///  @brief Holds DownloadCalibrationViewController object definition (OSX only).
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"

///
/// ViewController that allows downloading calibrations from videolat.org.
///
@interface DownloadCalibrationViewController : NSViewController<NewMeasurementDelegate, DownloadQueryDelegate> {
    NSArray *calibrations;	//!< Known calibrations as key/value pairs (from server).
}

@property(weak) IBOutlet NSPopUpButton *bCalibrations;	//!< UI element: the list of calibrations known.

- (IBAction) doDownload: (id)sender;	//!< Called when the user wants to download a calibration.
- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *)dataStore;	//!< Called after a calibration has downloaded.
- (void)availableCalibrations: (NSArray *)allCalibrations;	//!< Called to update the list of calibrations available on videolat.org

- (void)_updateCalibrations;	//!< Internal: populate bCalibrations.
- (void)_downloadCalibration: (NSDictionary *)calibration;	//!< Start downloading a single calibration
- (void)_listCalibrations;	//!< Get an updated list of calibrations from videolat.org.
@end
