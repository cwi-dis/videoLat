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
@interface UploadHelper : NSObject {
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
- (void)_doit;
- (void)_done: (NSData *)result;
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
	NSObject<NewMeasurementDelegate> *delegate;
}
- (UploadHelper *)initWithURL: (NSURL *)_baseURL dict: (NSDictionary *)calibrationData;
- (void)_done: (NSData *)result;
- (void)download: (id<NewMeasurementDelegate>) _delegate;
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
		if (![CalibrationSharing isUploadable: dataStore]) {
			return nil;
		}
		measurementTypeID = dataStore.measurementType;
		MeasurementType *myType = [MeasurementType forType: measurementTypeID];
		// Get relevant parameters
		uuid = dataStore.uuid;
		
		if (!myType.outputOnlyCalibration) {
			machineTypeID = dataStore.input.machineTypeID;
#if TARGET_OS_IPHONE
            deviceTypeID = dataStore.input.device;	// deviceID would be better but is unreadable...
#else
            deviceTypeID = dataStore.input.deviceID;	// deviceID would be better but is unreadable...
#endif
		}
		
		if (!myType.inputOnlyCalibration) {
			machineTypeID = dataStore.output.machineTypeID;
			deviceTypeID = dataStore.output.device;   // Note: the device name is the best we have, the device ID is unique
		}
	}
    return self;
}

- (void)_fillURLWithOp:(NSString *)op
{
    NSString *query = [NSString stringWithFormat:@"?op=%@", op];
    if (measurementTypeID) query = [NSString stringWithFormat: @"%@&measurementTypeID=%@", query, [measurementTypeID stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
    if (uuid) query = [NSString stringWithFormat: @"%@&uuid=%@", query, [uuid stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
    if (machineTypeID) query = [NSString stringWithFormat: @"%@&machineTypeID=%@", query, [machineTypeID stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
    if (deviceTypeID) query = [NSString stringWithFormat: @"%@&deviceTypeID=%@", query, [deviceTypeID stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
	if (data) query = [NSString stringWithFormat: @"%@&dataSize=%ld", query, (long)[data length]];
    url = [NSURL URLWithString: [NSString stringWithFormat: @"%@%@", [baseURL absoluteString], query]];
}

- (void)uploadAsynchronously
{
	data = [NSKeyedArchiver archivedDataWithRootObject: dataStore];
    [self _fillURLWithOp:@"upload"];
    NSLog(@"uploadAsynchronously: URL=%@", url);
    [self _doit];
}

- (void)_doit
{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: url];
    if (req == nil) {
        NSLog(@"UploadHelper: NSMutableURLRequest returned nil for %@", url);
        return;
    }
    
    if (data) {
        req.HTTPBody = data;
        req.HTTPMethod = @"PUT";
    }
    [[[NSURLSession sharedSession] dataTaskWithRequest:req
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         if (error) {
                                             showWarningAlert([error localizedDescription]);
                                         } else {
                                             [self _done: data];
                                         }
                                     }] resume];
}

- (void)_done: (NSData *)result
{
    char *s_result = (char *)[data bytes];
    if (strncmp(s_result, "YES\n", 4) == 0) {
        NSLog(@"Upload successful");
    } else if (strncmp(s_result, "NO\n", 3) == 0) {
        NSLog(@"Upload rejected");
        showWarningAlert(@"Upload rejected by server");
    } else {
        NSLog(@"UploadHelper: Unexpected reply, starting with %40.40s", s_result);
        showWarningAlert([NSString stringWithFormat: @"UploadHelper: Unexpected reply, starting with %40.40s", s_result]);
        if (VL_DEBUG) NSLog(@"Unexpected reply: \n%s", s_result);
    }
}
@end

@implementation UploadQueryHelper

- (void)shouldUpload: (id<UploadQueryDelegate>)_delegate
{
    delegate = _delegate;
    [self _fillURLWithOp:@"check"];
    NSLog(@"shouldUpload: URL=%@", url);
	[self _doit];
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
		if (VL_DEBUG) NSLog(@"\n%s", s_result);
	}
}

@end

@implementation ListHelper
- (ListHelper *)initWithURL: (NSURL *)_baseURL machine: (NSString *)_machineTypeID devices: (NSArray *)deviceTypeIDs
{
	self = [super initWithURL: _baseURL dataStore: nil];
	if (self) {
		NSString *query = [NSString stringWithFormat:@"?op=list"];
		if (_machineTypeID) query = [NSString stringWithFormat: @"%@&machineTypeID=%@", query, [_machineTypeID stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
		NSString *_deviceTypeID;
		for (_deviceTypeID in deviceTypeIDs) {
			query = [NSString stringWithFormat: @"%@&deviceTypeID=%@", query, [_deviceTypeID stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
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
	NSLog(@"plist=%@", plist);
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
    // url has been filled by init already
    NSLog(@"list: URL=%@", url);
	[self _doit];
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
    MeasurementDataStore *_dataStore;
    @try {
        _dataStore = [NSKeyedUnarchiver unarchiveObjectWithData: result];
    } @catch(NSException *ex) {
        NSLog(@"DownloadHelper: could not unarchive result");
        if (VL_DEBUG) NSLog(@"Data=%s", (char *)[result bytes]);
        [delegate performSelectorOnMainThread: @selector(openUntitledDocumentWithMeasurement:) withObject: nil waitUntilDone: NO];
        return;
    }
	if (result == nil) {
		NSLog(@"DownloadHelper: could not unarchive result");
        [delegate performSelectorOnMainThread: @selector(openUntitledDocumentWithMeasurement:) withObject: nil waitUntilDone: NO];
		return;
	}
    [delegate performSelectorOnMainThread: @selector(openUntitledDocumentWithMeasurement:) withObject: _dataStore waitUntilDone: NO];
}

- (void)download: (id<NewMeasurementDelegate>)_delegate
{
    delegate = (NSObject<NewMeasurementDelegate> *)_delegate;
    [self _fillURLWithOp:@"get"];
    NSLog(@"download: URL=%@", url);
	[self _doit];
}

@end

@implementation CalibrationSharing


+ (CalibrationSharing *)sharedUploader
{
    static CalibrationSharing *shared = nil;
    if (shared == nil) {
		NSString *server = [[NSUserDefaults standardUserDefaults] stringForKey:@"calibrationServer"];
		if (server == nil) {
			server = @"http://videolat.org/cgi-bin/videoLatCalibrationSharing.cgi";
			[[NSUserDefaults standardUserDefaults] setObject: server forKey: @"calibrationServer"];
		}
        shared = [[CalibrationSharing alloc] initWithServer: [NSURL URLWithString: server]];
    }
    return shared;
}

+ (BOOL)isUploadable:(MeasurementDataStore *)dataStore
{
	NSString *measurementTypeID = dataStore.measurementType;
	MeasurementType *myType = [MeasurementType forType: measurementTypeID];
	
	// First check: we only want to upload calibrations, and we want them to be consistent.
	
	if (!myType.isCalibration) return NO;

#if 0
	// Axctually, we only want to upload single-ended measurements
	if (!myType.outputOnlyCalibration && !myType.inputOnlyCalibration) {
		return NO;
	}
#endif

	if (!myType.outputOnlyCalibration) {
		if (dataStore.input == nil) {
			NSLog(@"UploadHelper: not output-only calibration but missing input device");
			return NO;
		}
	}
	
	if (!myType.inputOnlyCalibration) {
		if (dataStore.input == nil) {
			NSLog(@"UploadHelper: not output-only calibration but missing input device");
			return NO;
		}
	}
	return YES;
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

- (void)downloadAsynchronously: (NSDictionary *)calibration delegate: (id<NewMeasurementDelegate>) delegate
{
    DownloadHelper *helper = [[DownloadHelper alloc] initWithURL: baseURL dict: calibration];
    if (helper) {
        [helper download: delegate];
    }
}

@end
