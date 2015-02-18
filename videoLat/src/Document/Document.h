///
///  @file Document.h
///  @brief Defines Document object, part of the standard Cocoa application structure
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Cocoa/Cocoa.h>
#import "MeasurementDataStore.h"
#import "MeasurementDistribution.h"
#import "MeasurementType.h"

///
/// Subclass of NSDocument for a videoLat measurement run.
/// Contains references to all measurements and the distribution, and provides accessors for all the
/// metadata.
///
/// There is one twist: while we are creating a new document the normal document view window is hidden,
/// and a window from NewMeasurement.xib is shown. This controls the measurement process.
/// When the measurement run has completed that window disappears and the document window is shown.
///
@interface Document : NSDocument <NSWindowDelegate> {
    NSArray *objectsForNewDocument;                 //!< Internal: stores NIB-created objects for new measurement window so these are refcounted correctly
	MeasurementType *myType;                        //!< Internal: type of dataStore measurement
}
@property(readonly) NSString* measurementType;      //!< accessor for dataStore metadata variable
@property(readonly) NSString* baseMeasurementID;    //!< accessor for dataStore metadata variable
@property(readonly) NSString* machineTypeID;            //!< accessor for dataStore metadata variable
@property(readonly) NSString* machine;              //!< accessor for dataStore metadata variable
@property(readonly) NSString* inputDeviceID;        //!< accessor for dataStore metadata variable
@property(readonly) NSString* inputDevice;          //!< accessor for dataStore metadata variable
@property(readonly) NSString* outputDeviceID;       //!< accessor for dataStore metadata variable
@property(readonly) NSString* outputDevice;         //!< accessor for dataStore metadata variable
@property(strong) NSString* description;            //!< accessor for dataStore metadata variable
@property(strong) NSString* date;                   //!< accessor for dataStore metadata variable
@property(strong) NSString* location;               //!< accessor for dataStore metadata variable

@property(strong) IBOutlet MeasurementDataStore *dataStore; //!< data for this document
@property(strong) IBOutlet MeasurementDistribution *dataDistribution;   //!< distribution of dataStore
@property(strong) IBOutlet id myView;   //!< xxx
@property(assign) IBOutlet NSWindow *measurementWindow; //!< During new measurement: window containing the NewMeasurement objects

- (IBAction)newDocumentComplete: (id)sender;        //!< Callback used by NewMeasurement to signal it has finished.
- (IBAction)export: (id)sender; //!< Ask user for three filenames and export CSV files for data, distribution and metadata
- (BOOL)_exportCSV: (NSString *)csvData forType: (NSString *)descr title: (NSString *)title; //!< Internal helper for export: ask for filename and export one CSV file
- (NSString *) asCSVString; //!< Helper for _exportCSV: return metadata as CSV string
- (void)changed;    //!< Increment document change count. Unused?
- (void)_setCalibrationFileName;    //!< Internal: invent unique filename for new calibration run documents
@end
