///
///  @file CalibrationSharing.h
///  @brief Objects to upload and download calibrations to videoLat.org.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "protocols.h"
#import "MeasurementDataStore.h"

///
/// Object to handle uploading, listing and downloading of calibrations to videolat.org.
///
@interface CalibrationSharing : NSObject {
    NSURL *baseURL;	//!< URL for the sharing server
}

+ (CalibrationSharing *)sharedUploader;	//!< Return singleton object.
+ (BOOL)isUploadable:(MeasurementDataStore *)dataStore;	//!< Return true if this dataStore is uploadable.

- initWithServer: (NSURL *)server;	//!< Initialize the object for a given URL.

/// Test whether the server wants this measurement.
- (void)shouldUpload: (MeasurementDataStore *)dataStore delegate: (id<UploadQueryDelegate>) delegate;

/// Upload this measurement to the server.
- (void)uploadAsynchronously: (MeasurementDataStore *)dataStore;

/// Ask the server to report a list of calibrations available for this hardware.
- (void)listForMachine: (NSString *)machineTypeID andDevices: (NSArray *)deviceTypeIDs delegate: (id<DownloadQueryDelegate>) delegate;

/// Ask the server to send us a specific calibration.
- (void)downloadAsynchronously: (NSDictionary *)calibration delegate: (id<NewMeasurementDelegate>) delegate;

@end
