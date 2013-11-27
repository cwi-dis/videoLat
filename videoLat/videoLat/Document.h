//
//  Document.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MeasurementDataStore.h"
#import "MeasurementDistribution.h"
#import "MeasurementType.h"

@interface Document : NSDocument {
    NSArray *objectsForNewDocument;
	MeasurementType *myType;
}
@property(readonly) NSString* measurementType;
@property(readonly) NSString* baseMeasurementID;
@property(readonly) NSString* inputDeviceID;
@property(readonly) NSString* inputDevice;
@property(readonly) NSString* outputDeviceID;
@property(readonly) NSString* outputDevice;
@property(retain) NSString* description;
@property(retain) NSString* date;
@property(retain) NSString* location;

@property(retain) IBOutlet MeasurementDataStore *dataStore;
@property(retain) IBOutlet MeasurementDistribution *dataDistribution;
@property(retain) IBOutlet id myView;
@property(retain) IBOutlet NSWindow *measurementWindow;

- (IBAction)newDocumentComplete: (id)sender;
- (IBAction)export: (id)sender;
- (BOOL)_exportCSV: (NSString *)csvData forType: (NSString *)descr title: (NSString *)title;
- (NSString *) asCSVString;
- (void)changed;
- (void)_setCalibrationFileName;
@end
