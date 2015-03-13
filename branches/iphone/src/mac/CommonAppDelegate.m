//
//  CommonAppDelegate.m
//  
//
//  Created by Jack Jansen on 13/03/15.
//
//

#import "CommonAppDelegate.h"

@implementation CommonAppDelegate

@synthesize measurementTypes;
static void showErrorAlert(NSError *error) {
#if TARGET_OS_IPHONE
	[[[UIAlertView alloc] initWithTitle:error.localizedDescription
                            message:error.localizedRecoverySuggestion
                           delegate:nil
                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                  otherButtonTitles:nil, nil] show];
#else
	NSAlert *alert = [NSAlert alertWithError:error];
	[alert runModal];
#endif
}

- (CommonAppDelegate *)init
{
    self = [super init];
    if (self) {
        uuidToURL = [[NSMutableDictionary alloc] init];
    }
    return self;
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
                                               userInfo:@{NSLocalizedDescriptionKey : @"This is not a videoLat file"}];
        return NO;
    }
    str = [dict objectForKey:@"version"];
    if (![str isEqualToString:VIDEOLAT_FILE_VERSION]) {
        if (outError) {
            *outError = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError
                                               userInfo:@{NSLocalizedDescriptionKey : @"Unsupported version in videoLat file"}];
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
#if TARGET_OS_IPHONE
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.videoLat.org"]];
#else
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.videoLat.org"]];
#endif
}


@end
