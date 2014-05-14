//
//  Document.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Cocoa/Cocoa.h>
#import "MeasurementDataStore.h"
#import "MeasurementDistribution.h"
#import "MeasurementType.h"

@interface Document : NSDocument <NSWindowDelegate> {
    NSArray *objectsForNewDocument;
	MeasurementType *myType;
}
@property(readonly) NSString* measurementType;
@property(readonly) NSString* baseMeasurementID;
@property(readonly) NSString* machineID;
@property(readonly) NSString* machine;
@property(readonly) NSString* inputDeviceID;
@property(readonly) NSString* inputDevice;
@property(readonly) NSString* outputDeviceID;
@property(readonly) NSString* outputDevice;
@property(strong) NSString* description;
@property(strong) NSString* date;
@property(strong) NSString* location;

@property(strong) IBOutlet MeasurementDataStore *dataStore;
@property(strong) IBOutlet MeasurementDistribution *dataDistribution;
@property(strong) IBOutlet id myView;
@property(assign) IBOutlet NSWindow *measurementWindow;

- (IBAction)newDocumentComplete: (id)sender;
- (IBAction)export: (id)sender;
- (BOOL)_exportCSV: (NSString *)csvData forType: (NSString *)descr title: (NSString *)title;
- (NSString *) asCSVString;
- (void)changed;
- (void)_setCalibrationFileName;
@end
