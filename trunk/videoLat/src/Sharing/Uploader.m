//
//  Uploader.m
//  videoLat
//
//  Created by Jack Jansen on 05/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "Uploader.h"
#import "MeasurementType.h"

@interface UploadHelper : NSThread  {
    NSURL *baseURL;
    NSURL *url;
    MeasurementDataStore *dataStore;
	NSData *data;
    NSString *measurementTypeID;
    NSString *machineTypeID;
    NSString *inputDeviceTypeID;
    NSString *outputDeviceTypeID;
    NSString *uuid;
    id<UploadQueryDelegate> delegate;
}

- (UploadHelper *)initWithURL: (NSURL *)_baseURL dataStore: (MeasurementDataStore *)_dataStore;
- (void)shouldUpload: (id<UploadQueryDelegate>)_delegate;
- (void)uploadAsynchronously;
- (void)_fillURLWithOp: (NSString *)op;
- (void)main;

@end

@implementation UploadHelper
- (UploadHelper *)initWithURL: (NSURL *)_baseURL dataStore: (MeasurementDataStore *)_dataStore
{
    self = [super init];
    if (self == nil) return nil;
    baseURL = _baseURL;
    url = nil;
    dataStore = _dataStore;
	data = nil;
    measurementTypeID = dataStore.measurementType;
    machineTypeID = nil;
    inputDeviceTypeID = nil;
    outputDeviceTypeID = nil;
    uuid = nil;
    MeasurementType *myType = [MeasurementType forType: measurementTypeID];
    
    // First check: we only want to upload calibrations, and we want them to be consistent.
    
    if (!myType.isCalibration) return nil;
#if 1
    // Axctually, we only want to upload single-ended measurements
    if (!myType.outputOnlyCalibration && !myType.inputOnlyCalibration) {
        return nil;
    }
#else
    if (!myType.outputOnlyCalibration && !myType.inputOnlyCalibration) {
        if (![dataStore.input.machineTypeID isEqualToString: dataStore.output.machineTypeID]) {
            NSLog(@"sharedUploader: inconsistent machineTypeID input=%@ output=%@", dataStore.input.machineTypeID, dataStore.output.machineTypeID);
            return nil;
        }
    }
#endif
    // Get relevant parameters
    uuid = dataStore.uuid;
    
    if (!myType.outputOnlyCalibration) {
        if (dataStore.input == nil) {
            NSLog(@"sharedUploader: not output-only calibration but missing input device");
            return nil;
        }
        machineTypeID = dataStore.input.machineTypeID;
        inputDeviceTypeID = dataStore.input.deviceID;
    }
    
    if (!myType.inputOnlyCalibration) {
        if (dataStore.input == nil) {
            NSLog(@"sharedUploader: not output-only calibration but missing input device");
            return nil;
        }
        machineTypeID = dataStore.output.machineTypeID;
        outputDeviceTypeID = dataStore.output.device;   // Note: the device name is the best we have, the device ID is unique
    }
    
    return self;
}

- (void)_fillURLWithOp:(NSString *)op
{
    NSString *query = [NSString stringWithFormat:@"?op=%@", op];
    if (measurementTypeID) query = [NSString stringWithFormat: @"%@&measurementTypeID=%@", query, [measurementTypeID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if (uuid) query = [NSString stringWithFormat: @"%@&uuid=%@", query, [uuid stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if (machineTypeID) query = [NSString stringWithFormat: @"%@&machineTypeID=%@", query, [machineTypeID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if (inputDeviceTypeID) query = [NSString stringWithFormat: @"%@&inputDeviceTypeID=%@", query, [inputDeviceTypeID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if (outputDeviceTypeID) query = [NSString stringWithFormat: @"%@&outputDeviceTypeID=%@", query, [outputDeviceTypeID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if (data) query = [NSString stringWithFormat: @"%@&dataSize=%ld", query, (long)[data length]];
    url = [NSURL URLWithString: [NSString stringWithFormat: @"%@%@", [baseURL absoluteString], query]];
}

- (void)shouldUpload: (id<UploadQueryDelegate>)_delegate
{
    delegate = _delegate;
    [self _fillURLWithOp:@"check"];
    NSLog(@"shouldUpload: URL=%@", url);
	[self start];
}

- (void)uploadAsynchronously
{
	data = [NSKeyedArchiver archivedDataWithRootObject: dataStore];
    [self _fillURLWithOp:@"upload"];
    NSLog(@"uploadAsynchronously: URL=%@", url);
	[self start];
}

- (void) main
{
	NSLog(@"UploadHelper thread started");
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: url];
	if (req == nil) {
		NSLog(@"UploadHelper: NSMutableURLRequest returned nil for %@", url);
		return;
	}

	if (data) {
		req.HTTPBody = data;
		req.HTTPMethod = @"PUT";
	}

	if (![NSURLConnection canHandleRequest: req]) {
		NSLog(@"UploadHelper: NSURLConnection cannot handle request for %@", url);
		return;
	}

	NSURLResponse *resp;
	NSError *err;
	NSData *result = [NSURLConnection sendSynchronousRequest: req returningResponse:&resp error:&err];
	if (result == nil) {
		NSLog(@"UploadHelper: sendSynchronousRequest failed, error=%@", err);
		return;
	}

	if (VL_DEBUG) NSLog(@"UploadHelper: sendSynchronousRequest returned %@", result);
	char *s_result = (char *)[result bytes];
	if (strncmp(s_result, "YES\n", 4) == 0) {
		if (delegate) [delegate shouldUpload: YES];
	} else if (strncmp(s_result, "NO\n", 3) == 0) {
		if (delegate) [delegate shouldUpload: NO];
	} else {
		NSLog(@"UploadHelper: Unexpected reply, starting with %40.40s", s_result);
		if (VL_DEBUG) NSLog(@"%s", s_result);
	}
}

@end

@implementation Uploader


+ (Uploader *)sharedUploader
{
    static Uploader *shared = nil;
    if (shared == nil) {
        shared = [[Uploader alloc] initWithServer: [NSURL URLWithString: @"http://localhost/~jack/cgi-bin/uploadServer.cgi"]];
    }
    return shared;
}

- initWithServer: (NSURL *)server
{
    self = [super init];
    if (self) {
        baseURL = server;
    }
    return self;
}

- (void)shouldUpload: (MeasurementDataStore *)dataStore delegate: (id<UploadQueryDelegate>) delegate
{
    UploadHelper *helper = [[UploadHelper alloc] initWithURL: baseURL dataStore: dataStore];
    if (helper) {
        [helper shouldUpload: delegate];
    }
    
}

- (void)uploadAsynchronously: (MeasurementDataStore *)dataStore
{
    UploadHelper *helper = [[UploadHelper alloc] initWithURL: baseURL dataStore: dataStore];
    if (helper) {
        [helper uploadAsynchronously];
    }
}

@end
