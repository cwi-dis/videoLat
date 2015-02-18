//
//  Document.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "Document.h"
#import "DocumentView.h"
#import "appDelegate.h"

@implementation Document
@synthesize dataStore;
@synthesize dataDistribution;
@synthesize measurementWindow;

- (NSString*) measurementType { return self.dataStore?self.dataStore.measurementType:@""; }
- (NSString*) inputBaseMeasurementID { return self.dataStore?self.dataStore.inputBaseMeasurementID:nil; }
- (NSString*) inputMachineTypeID { return self.dataStore?self.dataStore.inputMachineTypeID:@""; }
- (NSString*) inputMachineID { return self.dataStore?self.dataStore.inputMachineID:@""; }
- (NSString*) inputMachine { return self.dataStore?self.dataStore.inputMachine:@""; }
- (NSString*) inputDeviceID { return self.dataStore?self.dataStore.inputDeviceID:@""; }
- (NSString*) inputDevice { return self.dataStore?self.dataStore.inputDevice:@""; }
- (NSString*) outputBaseMeasurementID { return self.dataStore?self.dataStore.outputBaseMeasurementID:nil; }
- (NSString*) outputMachineTypeID { return self.dataStore?self.dataStore.outputMachineTypeID:@""; }
- (NSString*) outputMachineID { return self.dataStore?self.dataStore.outputMachineID:@""; }
- (NSString*) outputMachine { return self.dataStore?self.dataStore.outputMachine:@""; }
- (NSString*) outputDeviceID { return self.dataStore?self.dataStore.outputDeviceID:@""; }
- (NSString*) outputDevice { return self.dataStore?self.dataStore.outputDevice:@""; }
@synthesize description;
@synthesize date;
@synthesize inputLocation;
@synthesize outputLocation;

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
        if (VL_DEBUG) NSLog(@"Loaded NewMeasurement: %d, objects %@, window %@ controller %@\n", (int)ok, objectsForNewDocument, self.measurementWindow, self.measurementWindow.windowController);
        if (!ok) {
            if (outError)
                *outError = [[NSError alloc] initWithDomain:@"VideoLat" code:NSFileReadNoSuchFileError
                                                   userInfo:@{NSLocalizedDescriptionKey : @"Could not open NewMeasurement NIB file"}];
            return nil;
            
        }
		if (self.measurementWindow) {
			[self.measurementWindow makeKeyAndOrderFront:self];
#if 0
            // This may be needed on 10.7 (and 10.8?)
			// And it may work on 10.9 now I've changed the measurementWindow property to "assign"
            [self.measurementWindow setReleasedWhenClosed: YES];
#endif
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
    self.inputLocation = ((appDelegate *)[[NSApplication sharedApplication] delegate]).location; // XXXJACK wrong! May come from remote side!
    self.outputLocation = ((appDelegate *)[[NSApplication sharedApplication] delegate]).location; // XXXJACK wrong! May come from remote side!
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

- (void)windowWillClose:(NSNotification *)notification
{
	// The "new document" window is closing. Check whether it produced results.
	// But note this will also be called when closing the "save file" sheet....
	if (VL_DEBUG) NSLog(@"windowWillClose for new measurement window %@", [notification object]);
	if (self.measurementWindow) {
		if (VL_DEBUG) NSLog(@"Closing unfinished document");
        objectsForNewDocument = nil;
        //xxxjackKeepIt = self.measurementWindow;
		self.measurementWindow.delegate = nil;
		self.measurementWindow = nil;
		[self close];
	}
}

- (void)_setCalibrationFileName
{
    NSString *fileName = [NSString stringWithFormat: @"%@-%@-%@-%@.vlCalibration", self.dataStore.measurementType, self.dataStore.outputMachineTypeID, self.dataStore.outputDevice, self.dataStore.inputDevice];
    NSURL *dirUrl = [(appDelegate *)[[NSApplication sharedApplication] delegate] directoryForCalibrations];
    NSURL *fileUrl = [NSURL URLWithString:[fileName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] relativeToURL:dirUrl];
    [self setFileURL: fileUrl];
    [self setFileType: [self fileType]];
    [self setDisplayName:fileName];
}

- (BOOL)prepareSavePanel:(NSSavePanel*)panel
{
    if (myType.isCalibration) {
        NSURL *dirUrl = [(appDelegate *)[[NSApplication sharedApplication] delegate] directoryForCalibrations];
        if (VL_DEBUG) NSLog(@"prepareSavePanel, directory was %@", [panel directoryURL]);
        [panel setDirectoryURL:dirUrl];
        if (VL_DEBUG) NSLog(@"prepareSavePanel, directory is now %@", [panel directoryURL]);
        [panel setNameFieldStringValue:[self displayName]];
    }
    // XXXX Otherwise we should set it back to the original value (or do this after calibration save finishes?)
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
    [dict setObject:self.inputLocation forKey:@"inputLocation"];
    [dict setObject:self.outputLocation forKey:@"outputLocation"];
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
    self.inputLocation = [dict objectForKey: @"inputLocation"];
    self.outputLocation = [dict objectForKey: @"outputLocation"];
#if 1
    // Old version compatility
    if (!self.inputLocation) {
        self.inputLocation = self.outputLocation = [dict objectForKey: @"location"];
    }
#endif
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
    [rv appendFormat: @"outputBaseMeasurementID,\"%@\"\n", self.outputBaseMeasurementID];
    [rv appendFormat: @"outputMachineTypeID,\"%@\"\n", self.outputMachineTypeID];
    [rv appendFormat: @"outputMachineID,\"%@\"\n", self.outputMachineID];
    [rv appendFormat: @"outputMachine,\"%@\"\n", self.outputMachine];
    [rv appendFormat: @"outputLocation,\"%@\"\n", self.outputLocation];
    [rv appendFormat: @"outputDeviceID,\"%@\"\n", self.outputDeviceID];
    [rv appendFormat: @"outputDevice,\"%@\"\n", self.outputDevice];
    [rv appendFormat: @"inputBaseMeasurementID,\"%@\"\n", self.inputBaseMeasurementID];
    [rv appendFormat: @"inputMachineTypeID,\"%@\"\n", self.inputMachineTypeID];
    [rv appendFormat: @"inputMachineID,\"%@\"\n", self.inputMachineID];
    [rv appendFormat: @"inputMachine,\"%@\"\n", self.inputMachine];
    [rv appendFormat: @"inputLocation,\"%@\"\n", self.inputLocation];
	[rv appendFormat: @"inputDeviceID,\"%@\"\n", self.inputDeviceID];
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
