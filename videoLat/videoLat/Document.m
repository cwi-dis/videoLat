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
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:10];
    [dict setObject:@"videoLat" forKey:@"videoLat"];
    [dict setObject:@"0.2" forKey:@"version"];
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
        NSLog(@"XXXJACK This is not a videoLat file\n");
        if (outError) {
            *outError = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError
                                               userInfo:@{NSLocalizedDescriptionKey : @"This is not a videoLat file"}];
        }
        return NO;
    }
    str = [dict objectForKey:@"version"];
    if (![str isEqualToString:@"0.2"]) {
        NSLog(@"XXXJACK This is not a version 0.2 videoLat file\n");
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
