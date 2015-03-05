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


@interface Uploader : NSObject {
    NSURL *baseURL;
}

+ (Uploader *)sharedUploader;

- initWithServer: (NSURL *)server;

- (void)shouldUpload: (MeasurementDataStore *)dataStore delegate: (id<UploadQueryDelegate>) delegate;
- (void)uploadAsynchronously: (MeasurementDataStore *)dataStore;

@end
