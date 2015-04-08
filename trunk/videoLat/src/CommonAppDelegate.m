//
//  CommonAppDelegate.m
//  
//
//  Created by Jack Jansen on 13/03/15.
//
//

#import "CommonAppDelegate.h"
#import "VideoRunManager.h"
#import "VideoCalibrationRunManager.h"
#import "AudioRunManager.h"
#import "AudioCalibrationRunManager.h"
#import "NetworkRunManager.h"

#if !TARGET_OS_IPHONE
#import "HardwareRunManager.h"
#import "VideoMonoRunManager.h"
#endif
@implementation CommonAppDelegate

@synthesize measurementTypes;

- (CommonAppDelegate *)init
{
    self = [super init];
    if (self) {
        uuidToURL = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)initVideolat
{
    // Fill measurementTypes
    NSURL *url = [self directoryForCalibrations];
    if (url == nil) return;
    [self _loadCalibrationsFrom:url];
    
    // Initialize run manager classes. Should be done differently.
    [VideoRunManager class];
    [VideoCalibrationRunManager class];
    [AudioRunManager class];
    [AudioCalibrationRunManager class];
    [NetworkRunManager class];
#if !TARGET_OS_IPHONE
    [VideoMonoRunManager class];
    [HardwareRunManager class];
#endif
    
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
		showErrorAlert(error);
		return nil;
	}
	url = [url URLByAppendingPathComponent:@"videoLat" isDirectory:YES];
	url = [url URLByAppendingPathComponent:@"Calibrations" isDirectory:YES];
	BOOL ok = [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];
	if (!ok) {
		showErrorAlert(error);
		return nil;
	}
    if (VL_DEBUG) NSLog(@"directoryForCalibrations is %@", url);
	return url;
}

- (void)_loadCalibrationsFrom: (NSURL *)directory
{
	NSError *error;
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
	if (files == nil) {
		showErrorAlert(error);
		return;
	}
	for (NSURL *url in files) {
		NSError *error;
		BOOL ok = [self _loadCalibration: url error: &error];
		if (!ok) {
			showErrorAlert(error);
		}
	}
}

- (BOOL)_loadCalibration: (NSURL *)url error: (NSError **)outError
{
    if (VL_DEBUG) NSLog(@"loading calibration from %@\n", url);
	NSData *data = [NSData dataWithContentsOfURL: url];
    NSMutableDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    NSString *str;
    str = [dict objectForKey:@"videoLat"];
    if (![str isEqualToString:@"videoLat"]) {
		if (outError)
			*outError = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError
                                               userInfo:@{NSLocalizedDescriptionKey : @"This is not a videoLat file."}];
        return NO;
    }
    str = [dict objectForKey:@"version"];
    if (![str isEqualToString:VIDEOLAT_FILE_VERSION]) {
        if (outError) {
			NSString *messageString = [NSString stringWithFormat:@"Unsupported version (%@) videoLat file.", str];
            *outError = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError
                                               userInfo:@{NSLocalizedDescriptionKey : messageString}];
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
                                               userInfo:@{NSLocalizedDescriptionKey : @"No dataStore in videolat file."}];
        }
        return NO;
    }
    
    // Store the calibration in its measurementtype object
	MeasurementType *myType = [MeasurementType forType: dataStore.measurementType];
	[myType addMeasurement: dataStore];
    
    // And remember the URL by uuid
    NSString *uuid = dataStore.uuid;
    [uuidToURL setObject: url forKey:uuid];
	
	return YES;
}

- (BOOL)haveCalibration: (NSString *)uuid
{
    return [uuidToURL objectForKey: uuid] != nil;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	if (VL_DEBUG) NSLog(@"Location Manager update: %@", newLocation);
	self.location = newLocation.description;
}

- (IBAction)openWebsite:(id)sender
{
#ifdef WITH_UIKIT
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.videoLat.org"]];
#else
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.videoLat.org"]];
#endif
}


@end
