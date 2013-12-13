//
//  appDelegate.m
//  videoLat
//
//  Created by Jack Jansen on 22-11-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "appDelegate.h"
#import "VideoRunManager.h"
#import "VideoCalibrationRunManager.h"
#import "VideoMonoRunManager.h"


@implementation appDelegate
@synthesize measurementTypes;
@synthesize locationManager;
@synthesize location;

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	// Fill measurementTypes
	NSURL *url = [self directoryForCalibrations];
	if (url == nil) return;
	[self _loadCalibrationsFrom:url];
    
    // Initialize run manager classes. Should be done differently.
    [VideoRunManager initialize];
    [VideoCalibrationRunManager initialize];
	[VideoMonoRunManager initialize];

	// Initialize location manager stuff
	self.location = @"Unknown location";
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	self.locationManager.delegate = self;
	[self.locationManager startUpdatingLocation];	
}

- (NSURL *)directoryForCalibrations
{
	NSError *error;
	NSURL *url = [NSURL URLWithString:@"videoLat"];
	url = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL: url create:YES error:&error ];
	if (url == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return nil;
	}
	url = [url URLByAppendingPathComponent:@"videoLat" isDirectory:YES];
	url = [url URLByAppendingPathComponent:@"Calibrations" isDirectory:YES];
	BOOL ok = [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];
	if (!ok) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return nil;
	}
	return url;
}

- (void)_loadCalibrationsFrom: (NSURL *)directory
{
	NSError *error;
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
	if (files == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	for (NSURL *url in files) {
		NSError *error;
		BOOL ok = [self _loadCalibration: url error: &error];
		if (!ok) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
		}
	}
}

- (BOOL)_loadCalibration: (NSURL *)url error: (NSError **)outError
{
	NSData *data = [NSData dataWithContentsOfURL: url];
    NSMutableDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    NSString *str;
    str = [dict objectForKey:@"videoLat"];
    if (![str isEqualToString:@"videoLat"]) {
		if (outError)
			*outError = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError
                                               userInfo:@{NSLocalizedDescriptionKey : @"This is not a videoLat file"}];
        return NO;
    }
    str = [dict objectForKey:@"version"];
    if (![str isEqualToString:VIDEOLAT_FILE_VERSION]) {
        if (outError) {
            *outError = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError
                                               userInfo:@{NSLocalizedDescriptionKey : @"Unsupported videoLat version file"}];
        }
        return NO;
    }
//    self.description = [dict objectForKey: @"description"];
//    self.date = [dict objectForKey: @"date"];
//    self.location = [dict objectForKey: @"location"];
    MeasurementDataStore *dataStore = [dict objectForKey: @"dataStore"];
    if (!dataStore) {
        if (outError) {
            *outError = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError
                                               userInfo:@{NSLocalizedDescriptionKey : @"No dataStore in videolat file"}];
        }
        return NO;
    }
	MeasurementType *myType = [MeasurementType forType: dataStore.measurementType];
	[myType addMeasurement: dataStore];
	
	return YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	NSLog(@"Location Manager update: %@", newLocation);
	self.location = newLocation.description;
}

@end
