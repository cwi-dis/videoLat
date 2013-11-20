//
//  Document.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "Document.h"

@implementation Document
@synthesize dataStore;
@synthesize dataDistribution;
@synthesize measurementWindow;

- (NSString*) measurementType { return self.dataStore?self.dataStore.measurementType:@""; }
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
        NSLog(@"Document init\n");
    }
    return self;
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
        NSLog(@"initWithType: %@\n", typeName);
        self.dataStore = [[MeasurementRun alloc] init];
        objectsForNewDocument = nil;
		BOOL ok;
		if ([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
			NSArray *newObjects;
			ok = [[NSBundle mainBundle] loadNibNamed: @"NewMeasurement" owner: self topLevelObjects: &newObjects];
			objectsForNewDocument = newObjects;
		} else {
			ok = [NSBundle loadNibNamed:@"NewMeasurement" owner:self];
			objectsForNewDocument = [[NSMutableArray alloc] init];
		}
        NSLog(@"Loaded NewMeasurement: %d, objects %@\n", (int)ok, objectsForNewDocument);
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
    NSLog(@"New document complete\n");
    objectsForNewDocument = nil;
	self.dataDistribution = [[MeasurementDistribution alloc] initWithSource:self.dataStore];
	// Set location, etc
	self.location = @"somewhere";
	self.description = @"something";
	self.date = [[NSDate date] descriptionWithCalendarFormat:nil timeZone:nil locale:nil];
	
    [super makeWindowControllers];
    [self showWindows];
    for (NSWindowController *ctrl in self.windowControllers)
        [[ctrl window] setDocumentEdited: YES];
	if (self.measurementWindow) {
		[self.measurementWindow close];
		self.measurementWindow = nil;
	}
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	// Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
	// You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
	NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
	@throw exception;
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	// Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
	// You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
	// If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
	NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
	@throw exception;
	return YES;
}

- (void)awakeFromNib
{
    baseName = @"videoLat";
}

- (IBAction)export: (id)sender
{
    
	NSString *csvData = [self.dataStore asCSVString];
    NSString *fileName = [NSString stringWithFormat:@"/tmp/%@-measurements.csv", baseName];
	[csvData writeToFile:fileName atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
#if 0
	csvData = [self.dataDistribution asCSVString];
    fileName = [NSString stringWithFormat:@"/tmp/%@-distribution.csv", baseName];
	[csvData writeToFile:fileName atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];    
#endif
}

- (IBAction)save: (id)sender
{
    NSString *fileName = [NSString stringWithFormat:@"/tmp/%@.videoLat", baseName];
 	[NSKeyedArchiver archiveRootObject: dataStore toFile: fileName];
}

@end
