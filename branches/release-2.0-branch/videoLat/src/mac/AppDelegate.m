//
//  appDelegate.m
//  videoLat
//
//  Created by Jack Jansen on 22-11-10.
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "AppDelegate.h"
#import "Document.h"
#import "EventLogger.h"

@implementation AppDelegate
@synthesize locationManager;
@synthesize location;

- (void)applicationWillTerminate:(NSNotification *)notification
{
#ifdef WITH_LOGGING
	[[EventLogger sharedLogger] close];
#endif
	if (self.newdocWindow)
		[self.newdocWindow setDelegate:nil];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    [self initVideolat];
}

- (BOOL) applicationShouldOpenUntitledFile: (id)sender
{
	return NO;
}


- (IBAction)openCalibrationFolder:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[self directoryForCalibrations]];
}


- (IBAction)openHardwareFolder:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL: [self hardwareFolder]];
}

#ifdef WITH_LOGGING
- (IBAction)saveLogFile: (id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	savePanel.title = @"Save detailed logfile";
	savePanel.nameFieldStringValue = @"videoLat.log";
	savePanel.allowsOtherFileTypes = YES;
	[savePanel setExtensionHidden: NO];
	NSInteger rv = [savePanel runModal];
	if (rv == NSFileHandlingPanelOKButton) {
		[[EventLogger sharedLogger] save: savePanel.URL];
	}
}
#endif


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


- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *)dataStore
{
	if (VL_DEBUG) NSLog(@"openUntitledDocumentWithMeasurement: %@", dataStore);
	assert(dataStore);
    
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
