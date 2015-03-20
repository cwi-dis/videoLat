//
//  Uploader.h
//  videoLat
//
//  Created by Jack Jansen on 05/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "protocols.h"
#import "MeasurementDataStore.h"


@interface CalibrationSharing : NSObject {
    NSURL *baseURL;
}

+ (CalibrationSharing *)sharedUploader;

- initWithServer: (NSURL *)server;

- (void)shouldUpload: (MeasurementDataStore *)dataStore delegate: (id<UploadQueryDelegate>) delegate;
- (void)uploadAsynchronously: (MeasurementDataStore *)dataStore;
- (void)listForMachine: (NSString *)machineTypeID andDevices: (NSArray *)deviceTypeIDs delegate: (id<DownloadQueryDelegate>) delegate;
- (void)downloadAsynchronously: (NSDictionary *)calibration delegate: (id<NewMeasurementDelegate>) delegate;

@end
