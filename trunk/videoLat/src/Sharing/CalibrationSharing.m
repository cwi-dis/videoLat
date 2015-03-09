//
//  Uploader.m
//  videoLat
//
//  Created by Jack Jansen on 05/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "CalibrationSharing.h"
#import "MeasurementType.h"

///
/// UploadHelper - Helper class to handle uploads and upload queries.
/// Also superclass for downloads and download queries.
///
@interface UploadHelper : NSThread  {
    NSURL *baseURL;
    NSURL *url;
    MeasurementDataStore *dataStore;
	NSData *data;
    NSString *measurementTypeID;
    NSString *machineTypeID;
    NSString *deviceTypeID;
    NSString *uuid;
}

- (UploadHelper *)initWithURL: (NSURL *)_baseURL dataStore: (MeasurementDataStore *)_dataStore;
- (void)uploadAsynchronously;
- (void)_fillURLWithOp: (NSString *)op;
- (void)main;
@end

@interface UploadQueryHelper : UploadHelper {
    id<UploadQueryDelegate> delegate;
}
- (void)shouldUpload: (id<UploadQueryDelegate>)_delegate;
- (void)_done: (NSData *)result;
@end

@interface ListHelper : UploadHelper {
	id<DownloadQueryDelegate> delegate;
}
- (ListHelper *)initWithURL: (NSURL *)_baseURL machine: (NSString *)machineTypeID devices: (NSArray *)deviceTypeIDs;
- (void)_done: (NSData *)result;
- (void)list: (id<DownloadQueryDelegate>) _delegate;
@end

@interface DownloadHelper : UploadHelper {
	id<DownloadDelegate> delegate;
}
- (UploadHelper *)initWithURL: (NSURL *)_baseURL dict: (NSDictionary *)calibrationData;
- (void)_done: (NSData *)result;
- (void)download: (id<DownloadDelegate>) _delegate;
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
    measurementTypeID = nil;
    machineTypeID = nil;
    deviceTypeID = nil;
    uuid = nil;
	if (dataStore) {
		measurementTypeID = dataStore.measurementType;
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
				NSLog(@"UploadHelper: inconsistent machineTypeID input=%@ output=%@", dataStore.input.machineTypeID, dataStore.output.machineTypeID);
				return nil;
			}
		}
	#endif
		// Get relevant parameters
		uuid = dataStore.uuid;
		
		if (!myType.outputOnlyCalibration) {
			if (dataStore.input == nil) {
				NSLog(@"UploadHelper: not output-only calibration but missing input device");
				return nil;
			}
			machineTypeID = dataStore.input.machineTypeID;
			deviceTypeID = dataStore.input.deviceID;
		}
		
		if (!myType.inputOnlyCalibration) {
			if (dataStore.input == nil) {
				NSLog(@"UploadHelper: not output-only calibration but missing input device");
				return nil;
			}
			machineTypeID = dataStore.output.machineTypeID;
			deviceTypeID = dataStore.output.device;   // Note: the device name is the best we have, the device ID is unique
		}
	}
    return self;
}

- (void)_fillURLWithOp:(NSString *)op
{
    NSString *query = [NSString stringWithFormat:@"?op=%@", op];
    if (measurementTypeID) query = [NSString stringWithFormat: @"%@&measurementTypeID=%@", query, [measurementTypeID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if (uuid) query = [NSString stringWithFormat: @"%@&uuid=%@", query, [uuid stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if (machineTypeID) query = [NSString stringWithFormat: @"%@&machineTypeID=%@", query, [machineTypeID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if (deviceTypeID) query = [NSString stringWithFormat: @"%@&deviceTypeID=%@", query, [deviceTypeID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if (data) query = [NSString stringWithFormat: @"%@&dataSize=%ld", query, (long)[data length]];
    url = [NSURL URLWithString: [NSString stringWithFormat: @"%@%@", [baseURL absoluteString], query]];
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
	[self _done: result];
}

- (void)_done: (NSData *)result
{
	char *s_result = (char *)[result bytes];
	if (strncmp(s_result, "YES\n", 4) == 0) {
		NSLog(@"Upload successful");
	} else if (strncmp(s_result, "NO\n", 3) == 0) {
		NSLog(@"Upload rejected");
	} else {
		NSLog(@"UploadHelper: Unexpected reply, starting with %40.40s", s_result);
		if (1 || VL_DEBUG) NSLog(@"\n%s", s_result);
	}
}

@end

@implementation UploadQueryHelper

- (void)shouldUpload: (id<UploadQueryDelegate>)_delegate
{
    delegate = _delegate;
    [self _fillURLWithOp:@"check"];
    NSLog(@"shouldUpload: URL=%@", url);
	[self start];
}

- (void)_done: (NSData *)result
{
	char *s_result = (char *)[result bytes];
	if (strncmp(s_result, "YES\n", 4) == 0) {
		if (delegate) [delegate shouldUpload: YES];
	} else if (strncmp(s_result, "NO\n", 3) == 0) {
		if (delegate) [delegate shouldUpload: NO];
	} else {
		NSLog(@"UploadQueryHelper: Unexpected reply, starting with %40.40s", s_result);
		if (1 || VL_DEBUG) NSLog(@"\n%s", s_result);
	}
}

@end

@implementation ListHelper
- (ListHelper *)initWithURL: (NSURL *)_baseURL machine: (NSString *)_machineTypeID devices: (NSArray *)deviceTypeIDs
{
	self = [super initWithURL: _baseURL dataStore: nil];
	if (self) {
		NSString *query = [NSString stringWithFormat:@"?op=list"];
		if (_machineTypeID) query = [NSString stringWithFormat: @"%@&machineTypeID=%@", query, [_machineTypeID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		NSString *_deviceTypeID;
		for (_deviceTypeID in deviceTypeIDs) {
			query = [NSString stringWithFormat: @"%@&deviceTypeID=%@", query, [_deviceTypeID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}
		url = [NSURL URLWithString: [NSString stringWithFormat: @"%@%@", [baseURL absoluteString], query]];
	}
	return self;
}

- (void)_done: (NSData *)result
{
	NSError *error;
	NSObject *plist = [NSPropertyListSerialization propertyListWithData: result
                                            options: NSPropertyListImmutable
                                            format: nil
                                            error: &error];
	if (plist == nil) {
		NSLog(@"ListHelper: result cannot be parsed as property list: %@", error);
		return;
	}
	if (![plist isKindOfClass: [NSArray class]]) {
		NSLog(@"ListHelper: result is not an NSArray but %@", plist);
		return;
	}
	[delegate availableCalibrations: (NSArray *)plist];
}

- (void)list: (id<DownloadQueryDelegate>)_delegate
{
    delegate = _delegate;
    [self _fillURLWithOp:@"list"];
    NSLog(@"list: URL=%@", url);
	[self start];
}

@end


@implementation DownloadHelper
- (DownloadHelper *)initWithURL: (NSURL *)_baseURL dict: (NSDictionary *)calibrationData
{
    self = [super init];
    if (self == nil) return nil;
    baseURL = _baseURL;
    url = nil;
    dataStore = nil;
	data = nil;
    measurementTypeID = [calibrationData objectForKey: @"measurementTypeID"];
    machineTypeID = [calibrationData objectForKey: @"machineTypeID"];
    deviceTypeID = [calibrationData objectForKey: @"deviceTypeID"];
    uuid = [calibrationData objectForKey: @"uuid"];

    return self;
}

- (void)_done: (NSData *)result
{
	MeasurementDataStore *_dataStore = [NSKeyedUnarchiver unarchiveObjectWithData: result];
	if (result == nil) {
		NSLog(@"DownloadHelper: could not unarchive result");
		[delegate didDownload: nil];
		return;
	}
	[delegate didDownload: _dataStore];
}

- (void)download: (id<DownloadDelegate>)_delegate
{
    delegate = _delegate;
    [self _fillURLWithOp:@"get"];
    NSLog(@"download: URL=%@", url);
	[self start];
}

@end

@implementation CalibrationSharing


+ (CalibrationSharing *)sharedUploader
{
    static CalibrationSharing *shared = nil;
    if (shared == nil) {
        shared = [[CalibrationSharing alloc] initWithServer: [NSURL URLWithString: @"http://localhost/~jack/cgi-bin/uploadServer.cgi"]];
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
    UploadQueryHelper *helper = [[UploadQueryHelper alloc] initWithURL: baseURL dataStore: dataStore];
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

- (void)listForMachine: (NSString *)machineTypeID andDevices: (NSArray *)deviceTypeIDs delegate: (id<DownloadQueryDelegate>) delegate
{
    ListHelper *helper = [[ListHelper alloc] initWithURL: baseURL machine: machineTypeID devices: deviceTypeIDs];
    if (helper) {
        [helper list: delegate];
    }
}

- (void)downloadAsynchronously: (NSDictionary *)calibration delegate: (id<DownloadDelegate>) delegate
{
    DownloadHelper *helper = [[DownloadHelper alloc] initWithURL: baseURL dict: calibration];
    if (helper) {
        [helper download: delegate];
    }
}

@end
