//
//  Document.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "Document.h"
#import "DocumentView.h"
#import "AppDelegate.h"
#import "CalibrationSharing.h"

@implementation Document
@synthesize dataStore;
@synthesize dataDistribution;

#ifdef WITH_UIKIT
#define NSChangeDone UIDocumentChangeDone
#endif

#ifdef WITH_APPKIT
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
    // Finally see whether this document is worth uploading
    if (!dontUpload) {
        CalibrationSharing *uploader = [CalibrationSharing sharedUploader];
        [uploader shouldUpload:self.dataStore delegate:self];
    }
}
#endif

#ifdef WITH_UIKIT

+ (NSURL *)inventURLForDocument: (MeasurementDataStore *)dataStore
{
	NSURL *fileUrl;
	NSString *baseFileName = dataStore.defaultNameForDocument;
    NSString *extension = dataStore.defaultExtensionForDocument;
    int uniqueNumber = 0;
    do {
        NSString *unique = @"";
        if (uniqueNumber) {
            unique = [NSString stringWithFormat:@" (%d)", uniqueNumber];
        }
        NSString *fileName = [NSString stringWithFormat: @"%@%@.%@", baseFileName, unique, extension];
        NSURL *dirUrl;
        if (dataStore.isCalibration) {
            dirUrl = [(AppDelegate *)[[NSorUIApplication sharedApplication] delegate] directoryForCalibrations];
        } else {
            NSError *error;
            dirUrl = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL: nil create:YES error:&error ];
            if (dirUrl == nil) {
                showErrorAlert(error);
                return nil;
            }
        }
        fileUrl = [NSURL URLWithString:[fileName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] relativeToURL:dirUrl];
        // If the file exists we will try with a new extension
        uniqueNumber++;
    } while ([[NSFileManager defaultManager] fileExistsAtPath: [fileUrl path]]);
    return fileUrl;
}
#endif

- (IBAction)newDocumentComplete: (id)sender
{
    if (VL_DEBUG) NSLog(@"New document complete\n");
    // Keep the data
	self.dataDistribution = [[MeasurementDistribution alloc] initWithSource:self.dataStore];
	// Set location, etc
	self.dataStore.description = @"";
#ifdef WITH_UIKIT
	self.dataStore.date = [[NSDate date] description];
#else
	self.dataStore.date = [[NSDate date] descriptionWithCalendarFormat:nil timeZone:nil locale:nil];
#endif

    // Do the NSDocument things
	myType = [MeasurementType forType: self.dataStore.measurementType];
	[self performSelectorOnMainThread:@selector(_changed) withObject:nil waitUntilDone:NO];

#ifdef WITH_APPKIT
    // Set title/filename for calibration documents
    if (myType.isCalibration) {
        [self _setCalibrationFileName];
    }
    
    [super makeWindowControllers];
    [self showWindows];
#endif
    // Finally see whether this document is worth uploading
    CalibrationSharing *uploader = [CalibrationSharing sharedUploader];
    [uploader shouldUpload:self.dataStore delegate:self];
}

#ifdef WITH_APPKIT
- (void)_setCalibrationFileName
{
    NSString *fileName = [NSString stringWithFormat: @"%@-%@-%@-%@.vlCalibration", self.dataStore.measurementType, self.dataStore.output.machineTypeID, self.dataStore.output.device, self.dataStore.input.device];
    NSURL *dirUrl = [(AppDelegate *)[[NSorUIApplication sharedApplication] delegate] directoryForCalibrations];
    NSURL *fileUrl = [NSURL URLWithString:[fileName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] relativeToURL:dirUrl];
    [self setFileURL: fileUrl];
    [self setFileType: [self fileType]];
    [self setDisplayName:fileName];
}

- (BOOL)prepareSavePanel:(NSSavePanel*)panel
{
    if (myType.isCalibration) {
        NSURL *dirUrl = [(AppDelegate *)[[NSApplication sharedApplication] delegate] directoryForCalibrations];
        if (VL_DEBUG) NSLog(@"prepareSavePanel, directory was %@", [panel directoryURL]);
        [panel setDirectoryURL:dirUrl];
        if (VL_DEBUG) NSLog(@"prepareSavePanel, directory is now %@", [panel directoryURL]);
        [panel setNameFieldStringValue:[self displayName]];
    }
    // XXXX Otherwise we should set it back to the original value (or do this after calibration save finishes?)
    return YES;
}
#endif

+ (BOOL)autosavesInPlace
{
    return YES;
}

#ifdef WITH_UIKIT
- (id)contentsForType:(NSString *)typeName error:(NSError **)outError
#else
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
#endif
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:10];
    [dict setObject:@"videoLat" forKey:@"videoLat"];
    [dict setObject:VIDEOLAT_FILE_VERSION forKey:@"version"];
    [dict setObject:self.dataStore forKey:@"dataStore"];
    if (dontUpload) [dict setObject: [NSNumber numberWithBool: YES] forKey:@"dontUpload"];
    
    return [NSKeyedArchiver archivedDataWithRootObject: dict];
}

#ifdef WITH_UIKIT
- (BOOL)loadFromContents:(id)data ofType:(NSString *)typeName error:(NSError **)outError
#else
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
#endif
{
    NSMutableDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    NSString *str;
    str = [dict objectForKey:@"videoLat"];
    if (str == nil || ![str isEqualToString:@"videoLat"]) {
        if (outError) {
            *outError = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError
                                               userInfo:@{
                                                          NSLocalizedRecoverySuggestionErrorKey : @"This is not a videoLat file.",
                                                          }];
        }
        return NO;
    }
    str = [dict objectForKey:@"version"];
    if (![str isEqualToString:VIDEOLAT_FILE_VERSION]) {
        if (outError) {
            *outError = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError
                                               userInfo:@{
                                                          NSLocalizedRecoverySuggestionErrorKey :
                                                              [NSString stringWithFormat: @"Unsupported version (%@) in videoLat file. Visit www.videoLat.org for older versions of the application.", str],
                                                          }];
        }
        return NO;
    }
    self.dataStore = [dict objectForKey: @"dataStore"];
    self.dataDistribution = [[MeasurementDistribution alloc] initWithSource:self.dataStore];

    NSNumber *du = [dict objectForKey: @"dontUpload"];
    if (du && [du boolValue])
        dontUpload = YES;
    
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
#ifdef WITH_UIKIT
	assert(0);
#else
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
#endif
}

- (NSString *) asCSVString
{
	NSMutableString *rv;
	rv = [NSMutableString stringWithCapacity: 0];
	[rv appendString:@"key,value\n"];
	[rv appendFormat: @"measurementType,\"%@\"\n", self.dataStore.measurementType];
    [rv appendFormat: @"outputBaseMeasurementID,\"%@\"\n", self.dataStore.outputBaseMeasurementID];
    [rv appendFormat: @"outputMachineTypeID,\"%@\"\n", self.dataStore.output.machineTypeID];
    [rv appendFormat: @"outputMachineID,\"%@\"\n", self.dataStore.output.machineID];
    [rv appendFormat: @"outputMachine,\"%@\"\n", self.dataStore.output.machine];
    [rv appendFormat: @"outputLocation,\"%@\"\n", self.dataStore.output.location];
    [rv appendFormat: @"outputDeviceID,\"%@\"\n", self.dataStore.output.deviceID];
    [rv appendFormat: @"outputDevice,\"%@\"\n", self.dataStore.output.device];
    [rv appendFormat: @"inputBaseMeasurementID,\"%@\"\n", self.dataStore.inputBaseMeasurementID];
    [rv appendFormat: @"inputMachineTypeID,\"%@\"\n", self.dataStore.input.machineTypeID];
    [rv appendFormat: @"inputMachineID,\"%@\"\n", self.dataStore.input.machineID];
    [rv appendFormat: @"inputMachine,\"%@\"\n", self.dataStore.input.machine];
    [rv appendFormat: @"inputLocation,\"%@\"\n", self.dataStore.input.location];
	[rv appendFormat: @"inputDeviceID,\"%@\"\n", self.dataStore.input.deviceID];
	[rv appendFormat: @"outputDevice,\"%@\"\n", self.dataStore.output.device];
    [rv appendFormat: @"description,\"%@\"\n", self.dataStore.description];
    [rv appendFormat: @"uuid,\"%@\"\n", self.dataStore.uuid];
	[rv appendFormat: @"date,\"%@\"\n", self.dataStore.date];
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
    dontUpload = NO;
    [self _changed];
}

- (void)_changed
{
    [self updateChangeCount:NSChangeDone];
}

- (void)shouldUpload:(BOOL)answer
{
    if (answer) {
        [self performSelectorOnMainThread:@selector(_doShouldUpload) withObject:nil waitUntilDone:NO];
    } else {
		// A "No" answer from the server is different than no answer, it means that the
		// server doesn't want this calibration.
		dontUpload = YES;
		[self performSelectorOnMainThread:@selector(_changed) withObject:nil waitUntilDone:NO];
	}
}

- (void)_doShouldUpload
{
    
    NSLog(@"Should upload this document");
#ifdef WITH_UIKIT
    showWarningAlert(@"This calibration is not yet available on videolat.org for this device. You should consider uploading it.");
#else
    NSWindow *win = [self windowForSheet];
    CalibrationSharing *uploader = [CalibrationSharing sharedUploader];
    NSAlert *alert = [NSAlert alertWithMessageText:@"Do you want to share this calibration with other videoLat users?"
                                     defaultButton:@"Yes"
                                   alternateButton:@"Never"
                                       otherButton:@"Not now"
                         informativeTextWithFormat:@"videoLat.org has no calibration for this hardware combination yet."
                      "If you think your measurement is trustworthy you can share it with other people (anonymously)."
                      ];
    if (win) {
        [alert beginSheetModalForWindow: win completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertDefaultReturn) {
                [uploader uploadAsynchronously:self.dataStore];
            } else if (returnCode == NSAlertAlternateReturn) {
                dontUpload = YES;
                [self performSelectorOnMainThread:@selector(_changed) withObject:nil waitUntilDone:NO];
            }
        }];
    } else {
        NSModalResponse answer = [alert runModal];
        if (answer == NSAlertDefaultReturn) {
            [uploader uploadAsynchronously:self.dataStore];
        } else if (answer == NSAlertAlternateReturn) {
            dontUpload = YES;
            [self performSelectorOnMainThread:@selector(_changed) withObject:nil waitUntilDone:NO];
        }
    }
#endif
}

- (void)didUpload: (BOOL)answer
{
    if (answer) {
        dontUpload = YES;
        [self performSelectorOnMainThread:@selector(_changed) withObject:nil waitUntilDone:NO];
    }
}

#ifdef WITH_APPKIT
- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError
{
    if ([self.windowControllers count] == 0) return nil;
    NSWindow *oneWindow = [self.windowControllers[0] window];
    assert(oneWindow);
    NSView *oneView = [oneWindow contentView];
    assert(oneView);

	NSPrintInfo *pInfo = [NSPrintInfo sharedPrintInfo];
    [pInfo setLeftMargin:32];
    [pInfo setRightMargin:32];
    [pInfo setTopMargin:32];
    [pInfo setBottomMargin:32];
    [pInfo setHorizontalPagination:NSFitPagination];
    [pInfo setVerticallyCentered:NO];
    [[pInfo dictionary] addEntriesFromDictionary:printSettings];

	NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:oneView printInfo: pInfo];
    [printOp.printInfo.dictionary addEntriesFromDictionary:printSettings];
    return printOp;
}
#endif

@end
