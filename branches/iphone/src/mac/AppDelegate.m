//
//  appDelegate.m
//  videoLat
//
//  Created by Jack Jansen on 22-11-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "AppDelegate.h"
#import "VideoRunManager.h"
#import "VideoCalibrationRunManager.h"
#import "VideoMonoRunManager.h"
#import "HardwareRunManager.h"
#import "AudioRunManager.h"
#import "AudioCalibrationRunManager.h"
#import "NetworkRunManager.h"

@implementation AppDelegate
@synthesize measurementTypes;
@synthesize locationManager;
@synthesize location;

- (AppDelegate *)init
{
    self = [super init];
    if (self) {
        uuidToURL = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	// Fill measurementTypes
	NSURL *url = [self directoryForCalibrations];
	if (url == nil) return;
	[self _loadCalibrationsFrom:url];
    
    // Initialize run manager classes. Should be done differently.
    [VideoRunManager class];
    [VideoCalibrationRunManager class];
	[VideoMonoRunManager class];
    [HardwareRunManager class];
    [AudioRunManager class];
    [AudioCalibrationRunManager class];
    [NetworkRunManager class];

    // Initialize location manager stuff
	self.location = @"Unknown location";
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	self.locationManager.delegate = self;
	[self.locationManager startUpdatingLocation];	
}

- (BOOL) applicationShouldOpenUntitledFile: (id)sender
{
	return NO;
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
    if (VL_DEBUG) NSLog(@"directoryForCalibrations is %@", url);
	return url;
}

- (IBAction)openWebsite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.videoLat.org"]];
}

- (IBAction)openCalibrationFolder:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[self directoryForCalibrations]];
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

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	if (VL_DEBUG) NSLog(@"Location Manager update: %@", newLocation);
	self.location = newLocation.description;
}

- (IBAction)openHardwareFolder:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL: [self hardwareFolder]];
}

- (NSArray *)hardwareNames
{
    // We should dynamically determine this, but I am too lazy for now...
    return @[
             @"Arduino",
             @"LabJack"
             ];
}

- (NSURL *)hardwareFolder
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url = [bundle URLForResource:@"HardwareDevices" withExtension: nil];
    return url;
}

- (IBAction)newMeasurement:(id)sender
{
	if (self.newdocWindow == nil) {
		BOOL ok;
	#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
		if ([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
			NSArray *newObjects;
			ok = [[NSBundle mainBundle] loadNibNamed: @"NewMeasurementView" owner: self topLevelObjects: &newObjects];
			objectsForNewDocument = newObjects;
		} else
	#endif
		{
			ok = [NSBundle loadNibNamed:@"NewMeasurementView" owner:self];
			objectsForNewDocument = [[NSMutableArray alloc] init];
		}
		if (!ok) {
			NSLog(@"Could not open NewMeasurement NIB file");
			
		}
	}

    if (self.newdocWindow) {
        [self.newdocWindow setDelegate: self];
        [self.newdocWindow makeKeyAndOrderFront:self];
    }
}

- (void) windowWillClose: (NSNotification *)notification
{
    NSObject *obj = [notification object];
    if (obj == self.newdocWindow) {
		self.newdocWindow = nil;
        objectsForNewDocument = nil;
    }
}

- (BOOL)haveCalibration: (NSString *)uuid
{
    return [uuidToURL objectForKey: uuid] != nil;
}

- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *)dataStore
{
	if (VL_DEBUG) NSLog(@"openUntitledDocumentWithMeasurement: %@", dataStore);
    
    // If the document is a calibration we already know of (because we have it's uuid)
    // we open the calibration itself, in stead of an untitled document.
    NSString *uuid = dataStore.uuid;
    NSURL *calibrationURL = [uuidToURL objectForKey: uuid];
    if (calibrationURL) {
        if (VL_DEBUG) NSLog(@"Open existing document for %@", calibrationURL);
        [[NSDocumentController sharedDocumentController]
                    openDocumentWithContentsOfURL:calibrationURL
                    display:YES
                    completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {}
                    ];
        return;
    }
    
    // The normal case: this is a new document. Open a new empty document for it
	NSDocumentController *c = [NSDocumentController sharedDocumentController];
	NSError *error;
	Document *d = [c openUntitledDocumentAndDisplay: NO error:&error];
	if (d == nil) {
		NSLog(@"ERROR: %@", error);
		return;
	}
    
    // Now store the data in the document, and tell the document it can go initialize itself
	d.dataStore = dataStore;
	[d newDocumentComplete: self];

	// Finally we add the document to the list of known measurements, if it is a calibration
	// (so it becomes available during this run already). Unfortunately we cannot add it to the URL cache yet.
	// Store the calibration in its measurementtype object
	MeasurementType *myType = [MeasurementType forType: dataStore.measurementType];
	[myType addMeasurement: dataStore];
}
@end
