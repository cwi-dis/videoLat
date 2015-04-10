///
///  @file appDelegate.h
///  @brief Application delegate, part of the standard Cocoa application structure.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Cocoa/Cocoa.h>
#import "NewMeasurementView.h"

#import "CommonAppDelegate.h"

///
/// Application delegate. Stores application-global items, and implements application-global actions.
///
@interface AppDelegate : CommonAppDelegate <NSApplicationDelegate, NSWindowDelegate, NewMeasurementDelegate>{
    NSArray *objectsForNewDocument;     //!< Internal: stores NIB-created objects for new measurement window so these are refcounted correctly
         //!< All known calibrations, by UUID
}
   //!< Textual description of current GPS location
@property(weak) IBOutlet NSWindow *newdocWindow;

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification; //!< Standard method called to signal application start.
- (void)applicationWillTerminate:(NSNotification *)notification;	//!< Standard method called to signal application termination
- (BOOL) applicationShouldOpenUntitledFile: (id)sender;	//!< Standard method to ask whether an untilted document should be opened

// methods for instance variable 'uuidToURL'
- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *)dataStore;

- (IBAction)openCalibrationFolder:(id)sender;   //!< Method to be called when the user wants to view the calibration folder.

- (IBAction)openHardwareFolder:(id)sender;      //!< Method to be called when the user wants to view the hardware drivers folder.
- (IBAction)newMeasurement:(id)sender;          //!< Method to be called when the user wants to do a new measurement
- (IBAction)saveLogFile: (id)sender;			//!< Method called when the user wants to save a detailed log file
- (NSArray *)hardwareNames;                     //!< Names of all available hardware drivers
- (NSURL *)hardwareFolder;                      //!< URL of folder containing hardware drivers

- (void) windowWillClose: (NSNotification *)notification;
@end
