//
//  Document.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "Document.h"
#import "DocumentView.h"
#import "appDelegate.h"

@implementation Document
@synthesize dataStore;
@synthesize dataDistribution;
@synthesize measurementWindow;

- (NSString*) measurementType { return self.dataStore?self.dataStore.measurementType:@""; }
- (NSString*) baseMeasurementID { return self.dataStore?self.dataStore.baseMeasurementID:nil; }
- (NSString*) machineID { return self.dataStore?self.dataStore.machineID:@""; }
- (NSString*) machine { return self.dataStore?self.dataStore.machine:@""; }
- (NSString*) inputDeviceID { return self.dataStore?self.dataStore.inputDeviceID:@""; }
- (NSString*) inputDevice { return self.dataStore?self.dataStore.inputDevice:@""; }
- (NSString*) outputDeviceID { return self.dataStore?self.dataStore.outputDeviceID:@""; }
- (NSString*) outputDevice { return self.dataStore?self.dataStore.outputDevice:@""; }
@synthesize description;
@synthesize date;
@synthesize location;

- (id)init
{
    self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
        if (VL_DEBUG) NSLog(@"Document init\n");
    }
    return self;
}

- (void) dealloc
{
#if 0
	self.dataStore = nil;
	self.dataDistribution = nil;
	self.myView = nil;
	self.measurementWindow = nil;
#endif
}


- (void)makeWindowControllers
{
    if (self.measurementWindow == nil)
        [super makeWindowControllers];
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
    self = [super initWithType: typeName error: outError];
    if (self) {
        if (VL_DEBUG) NSLog(@"initWithType: %@\n", typeName);
        self.dataStore = [[MeasurementDataStore alloc] init];
        objectsForNewDocument = nil;
		BOOL ok;
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
		if ([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
			NSArray *newObjects;
			ok = [[NSBundle mainBundle] loadNibNamed: @"NewMeasurement" owner: self topLevelObjects: &newObjects];
			objectsForNewDocument = newObjects;
		} else
#endif
		{
			ok = [NSBundle loadNibNamed:@"NewMeasurement" owner:self];
			objectsForNewDocument = [[NSMutableArray alloc] init];
		}
        if (1 || VL_DEBUG) NSLog(@"Loaded NewMeasurement: %d, objects %@\n", (int)ok, objectsForNewDocument);
        if (!ok) {
            if (outError)
                *outError = [[NSError alloc] initWithDomain:@"VideoLat" code:NSFileReadNoSuchFileError
                                                   userInfo:@{NSLocalizedDescriptionKey : @"Could not open NewMeasurement NIB file"}];
            return nil;
            
        }
    }
    return self;
}

- (NSString *)windowNibName
{
	// Override returning the nib file name of the document
	// If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
	return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	// Add any code here that needs to be executed once the windowController has loaded the document's window.
    if (objectsForNewDocument) {
        // We have opened a new-measurement view.
        [[aController window] orderOut: self];
        for (id obj in objectsForNewDocument) {
            if ([obj respondsToSelector:@selector(makeKeyAndOrderFront:)])
                [obj makeKeyAndOrderFront: self];
        }
    }
}

- (IBAction)newDocumentComplete: (id)sender
{
    if (VL_DEBUG) NSLog(@"New document complete\n");
    objectsForNewDocument = nil;
    // Keep the data
	self.dataDistribution = [[MeasurementDistribution alloc] initWithSource:self.dataStore];
	// Set location, etc
	self.location = ((appDelegate *)[[NSApplication sharedApplication] delegate]).location;
	self.description = @"";
	self.date = [[NSDate date] descriptionWithCalendarFormat:nil timeZone:nil locale:nil];

    // Do the NSDocument things
	myType = [MeasurementType forType: self.dataStore.measurementType];
	[self updateChangeCount:NSChangeDone];

    // Set title/filename for calibration documents
    if (myType.isCalibration) {
        [self _setCalibrationFileName];
    }
    
    // Close the measurement window and open the document window
	if (self.measurementWindow) {
		NSWindow *windowTmp = self.measurementWindow;
		self.measurementWindow = nil;
        windowTmp.delegate = nil;
		[windowTmp close];
	}
    [super makeWindowControllers];
    [self showWindows];
    [(DocumentView *)self.myView updateView];
}

static NSWindow *xxxjackKeepIt;

- (void)windowWillClose:(NSNotification *)notification
{
	// The "new document" window is closing. Check whether it produced results.
	// But note this will also be called when closing the "save file" sheet....
	NSLog(@"windowWillClose for new measurement window %@", [notification object]);
	if (self.measurementWindow) {
		NSLog(@"Closing unfinished document");
        objectsForNewDocument = nil;
        xxxjackKeepIt = self.measurementWindow;
		self.measurementWindow = nil;
		[self close];
	}
}

- (void)_setCalibrationFileName
{
    NSString *fileName = [NSString stringWithFormat: @"%@-%@-%@-%@", self.dataStore.measurementType, self.dataStore.machine, self.dataStore.outputDevice, self.dataStore.inputDevice];
    [self setDisplayName:fileName];
}

- (BOOL)prepareSavePanel:(NSSavePanel*)panel
{
    if (myType.isCalibration) {
        NSURL *dirUrl = [(appDelegate *)[[NSApplication sharedApplication] delegate] directoryForCalibrations];
        [panel setDirectoryURL:dirUrl];
        [panel setNameFieldStringValue:[self displayName]];
    }
    return YES;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:10];
    [dict setObject:@"videoLat" forKey:@"videoLat"];
    [dict setObject:VIDEOLAT_FILE_VERSION forKey:@"version"];
    [dict setObject:self.description forKey:@"description"];
    [dict setObject:self.location forKey:@"location"];
    [dict setObject:self.date forKey:@"date"];
    [dict setObject:self.dataStore forKey:@"dataStore"];
//    [dict setObject:self.dataDistribution forKey:@"dataDistribution"];
    return [NSKeyedArchiver archivedDataWithRootObject: dict];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSMutableDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    NSString *str;
    str = [dict objectForKey:@"videoLat"];
    if (![str isEqualToString:@"videoLat"]) {
        if (outError) {
            *outError = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError
                                               userInfo:@{NSLocalizedDescriptionKey : @"This is not a videoLat file"}];
        }
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
    self.description = [dict objectForKey: @"description"];
    self.date = [dict objectForKey: @"date"];
    self.location = [dict objectForKey: @"location"];
    self.dataStore = [dict objectForKey: @"dataStore"];
//    self.dataDistribution = [dict objectForKey: @"dataDistribution"];
    self.dataDistribution = [[MeasurementDistribution alloc] initWithSource:self.dataStore];
    [self.myView updateView];

	myType = [MeasurementType forType: self.dataStore.measurementType];
	
	return YES;
}

- (void)awakeFromNib
{
}

- (IBAction)export: (id)sender
{
	NSString *csvData;
	BOOL ok;
	csvData = [self asCSVString];
	ok = [self _exportCSV: csvData forType: @"description" title: @"Export Measurement Description"];
	if (!ok) return;
	csvData = [self.dataStore asCSVString];
	ok = [self _exportCSV: csvData forType: @"measurements" title: @"Export Measurement Values"];
	if (!ok) return;
	csvData = [self.dataDistribution asCSVString];
	ok = [self _exportCSV: csvData forType: @"distribution" title: @"Export Measurement Distribution"];
	if (!ok) return;
}

- (BOOL)_exportCSV: (NSString *)csvData forType: (NSString *)descr title: (NSString *)title
{
	NSError *error;
    NSString *baseName = [self displayName];
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	savePanel.title = title;
	savePanel.nameFieldStringValue = [NSString stringWithFormat: @"%@-%@.csv", baseName, descr];
	savePanel.allowedFileTypes = @[ @"csv"];
	savePanel.allowsOtherFileTypes = YES;
	[savePanel setExtensionHidden: NO];
	NSInteger rv = [savePanel runModal];
	if (rv == NSFileHandlingPanelOKButton) {
		BOOL ok = [csvData writeToURL:savePanel.URL atomically:NO encoding:NSStringEncodingConversionAllowLossy error:&error];
		if (!ok) {
			NSAlert *alert =[NSAlert alertWithError:error];
			[alert runModal];
			return NO;
		}
	}
	return YES;
}

- (NSString *) asCSVString
{
	NSMutableString *rv;
	rv = [NSMutableString stringWithCapacity: 0];
	[rv appendString:@"key,value\n"];
	[rv appendFormat: @"measurementType,\"%@\"\n", self.measurementType];
	[rv appendFormat: @"baseMeasurementID,\"%@\"\n", self.baseMeasurementID];
	[rv appendFormat: @"inputDeviceID,\"%@\"\n", self.inputDeviceID];
	[rv appendFormat: @"inputDevice,\"%@\"\n", self.inputDevice];
	[rv appendFormat: @"outputDeviceID,\"%@\"\n", self.outputDeviceID];
	[rv appendFormat: @"outputDevice,\"%@\"\n", self.outputDevice];
	[rv appendFormat: @"description,\"%@\"\n", self.description];
	[rv appendFormat: @"date,\"%@\"\n", self.date];
	[rv appendFormat: @"min,%g\n", self.dataStore.min];
	[rv appendFormat: @"max,%g\n", self.dataStore.max];
	[rv appendFormat: @"average,%g\n", self.dataStore.average];
	[rv appendFormat: @"stddev,%g\n", self.dataStore.stddev];
	[rv appendFormat: @"baseMeasurementAverage,%g\n", self.dataStore.baseMeasurementAverage];
	[rv appendFormat: @"baseMeasurementStddev,%g\n", self.dataStore.baseMeasurementStddev];
	return rv;
}


- (void)changed
{
	[self updateChangeCount:NSChangeDone];
}
@end
