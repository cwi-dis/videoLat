///
///  @file Document.h
///  @brief Defines Document object, part of the standard Cocoa application structure
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "compat.h"
#import "MeasurementDataStore.h"
#import "MeasurementDistribution.h"
#import "MeasurementType.h"

///
/// Subclass of NSDocument or UIDocument for a videoLat measurement run.
/// Contains references to the measurements and the distribution.
///
@interface Document :
#ifdef WITH_UIKIT
	UIDocument <UploadQueryDelegate, UploadDelegate>
#else
	NSDocument <NSWindowDelegate, UploadQueryDelegate, UploadDelegate>
#endif
{
	MeasurementType *myType;    //!< Internal: type of dataStore measurement
    BOOL dontUpload;            //!< Internal: don't attempt uploading this document
}

@property(strong) IBOutlet MeasurementDataStore *dataStore; //!< data for this document
@property(strong) IBOutlet MeasurementDistribution *dataDistribution;   //!< distribution of dataStore

#ifdef WITH_UIKIT
/// Invent a filename for the given MeasurementDataStore object.
+ (NSURL *)inventURLForDocument: (MeasurementDataStore *)dataStore;
#endif
- (IBAction)newDocumentComplete: (id)sender;        //!< Callback used by NewMeasurement to signal it has finished.
- (IBAction)export: (id)sender; //!< Ask user for three filenames and export CSV files for data, distribution and metadata
- (BOOL)_exportCSV: (NSString *)csvData forType: (NSString *)descr title: (NSString *)title; //!< Internal helper for export: ask for filename and export one CSV file
- (NSString *) asCSVString; //!< Helper for _exportCSV: return metadata as CSV string
- (void)changed;    //!< Increment document change count because user made a change, also clears dontUpload flag
- (void)_changed;    //!< Internal: increment document change count.
- (void)shouldUpload: (BOOL)answer; //!< UploadQueryDelegate method called when the server answers whether or not to upload this document.
- (void)_doShouldUpload;            //!< Help for shouldUpload, runs in main thread

#ifdef WITH_APPKIT
- (void)_setCalibrationFileName;    //!< Internal: invent unique filename for new calibration run documents
#endif
@end
