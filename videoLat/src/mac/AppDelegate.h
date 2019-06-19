///
///  @file appDelegate.h
///  @brief Application delegate, part of the standard Cocoa application structure (OSX only).
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Cocoa/Cocoa.h>
#import "NewMeasurementView.h"

#import "CommonAppDelegate.h"

///
/// Application delegate.
/// Stores application-global items, and implements application-global actions.
///
@interface AppDelegate : CommonAppDelegate <NSApplicationDelegate, NSWindowDelegate, NewMeasurementDelegate>{
    NSArray *objectsForNewDocument;     //!< Internal: stores NIB-created objects for new measurement window so these are refcounted correctly
}

@property(weak) IBOutlet NSWindow *newdocWindow; //!< Reference to current "New Measurement" dialog, if any.

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification; //!< Standard method called to signal application start.
- (void)applicationWillTerminate:(NSNotification *)notification;	//!< Standard method called to signal application termination
- (BOOL)applicationShouldOpenUntitledFile: (id)sender;	//!< Standard method to ask whether an untitled document should be opened
- (BOOL)applicationOpenUntitledFile:(id)sender;          //!< Open an untitled file (new measurement)

/// Create and show a new document for a measurement.
/// @param dataStore The measurement data.
- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *)dataStore;

- (IBAction)openCalibrationFolder:(id)sender;   //!< Method to be called when the user wants to view the calibration folder.

- (IBAction)openHardwareFolder:(id)sender;      //!< Method to be called when the user wants to view the hardware drivers folder.
- (IBAction)newMeasurement:(id)sender;          //!< Method to be called when the user wants to do a new measurement
- (IBAction)saveLogFile: (id)sender;			//!< Method called when the user wants to save a detailed log file
- (NSArray *)hardwareNames;                     //!< Names of all available hardware drivers
- (NSURL *)hardwareFolder;                      //!< URL of folder containing hardware drivers

- (void) windowWillClose: (NSNotification *)notification;	//!< Called when the New Document window closes
@end
