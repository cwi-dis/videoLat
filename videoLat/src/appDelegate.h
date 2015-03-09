///
///  @file appDelegate.h
///  @brief Application delegate, part of the standard Cocoa application structure.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>
#import "protocols.h"
#import "MeasurementType.h"
#import "NewMeasurementView.h"

///
/// Application delegate. Stores application-global items, and implements application-global actions.
///
@interface appDelegate : NSObject <CLLocationManagerDelegate, NSApplicationDelegate, NSWindowDelegate>{
    NSArray *objectsForNewDocument;     //!< Internal: stores NIB-created objects for new measurement window so these are refcounted correctly
    NSMutableDictionary *uuidToURL;     //!< All known calibrations, by UUID
}
@property(strong) MeasurementType *measurementTypes;    //!< Object that stores all measurement type implementations
@property(strong) CLLocationManager *locationManager;   //!< CoreLocation object that sends us GPS position updates.
@property(strong) NSString *location;   //!< Textual description of current GPS location
@property(weak) IBOutlet NSWindow *newdocWindow;

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification; //!< Standard method called to signal application start.
- (BOOL) applicationShouldOpenUntitledFile: (id)sender;

- (NSURL *)directoryForCalibrations;    //!< Returns directory where calibration run documents should be stored/loaded.
- (void)_loadCalibrationsFrom: (NSURL *)directory;  //!< Internal helper for applicationWillFinishLaunching, loads all calibrations.
- (BOOL)_loadCalibration: (NSURL *)url error: (NSError **)outError;   //!< Helper for loadCalibrationsFrom, loads a single calibration.
- (BOOL)haveCalibration: (NSString *)uuid;

/// CoreLocation callback routine, called whenever location information is available (or changes).
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
- (IBAction)openWebsite:(id)sender; //!< Method to be called when the user wants to view the videoLat website.
- (IBAction)openCalibrationFolder:(id)sender;   //!< Method to be called when the user wants to view the calibration folder.

- (IBAction)openHardwareFolder:(id)sender;      //!< Method to be called when the user wants to view the hardware drivers folder.
- (IBAction)newMeasurement:(id)sender;          //!< Method to be called when the user wants to do a new measurement
- (NSArray *)hardwareNames;                     //!< Names of all available hardware drivers
- (NSURL *)hardwareFolder;                      //!< URL of folder containing hardware drivers

- (void) windowWillClose: (NSNotification *)notification;
- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *)dataStore;
@end
