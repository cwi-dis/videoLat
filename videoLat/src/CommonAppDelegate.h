///
///  @file CommonAppDelegate.h
///  @brief Application delegate code common to OSX and iOS.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <CoreLocation/CoreLocation.h>
#import "MeasurementType.h"
#import "protocols.h"

///
/// Per-application code common to iSO and OSX.
///
@interface CommonAppDelegate : NSObject <CLLocationManagerDelegate> {
    NSMutableDictionary *uuidToURL;	//!< Map measurement UUIDs to the URL of the file.
}

@property(strong) CLLocationManager *locationManager;	//!< Object that gives us GPS position information

@property(strong) NSString *location;	//!< Textual representation of current GPS position.

- (void)initVideolat;   //!< Initialize the app, common to OSX and iOS.
- (NSURL *)directoryForCalibrations;    //!< Returns directory where calibration run documents should be stored/loaded.
- (void)_loadCalibrationsFrom: (NSURL *)directory;  //!< Internal helper for applicationWillFinishLaunching, loads all calibrations.
- (void)_loadNullCalibration; //!< Internal helper to load the 0 duration calibration
- (BOOL)loadCalibration: (NSURL *)url error: (NSError **)outError;   //!< Helper for loadCalibrationsFrom, loads a single calibration.
- (BOOL)haveCalibration: (NSString *)uuid;
- (IBAction)openWebsite:(id)sender; //!< Method to be called when the user wants to view the videoLat website.

/// Location manager delegate method.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)newLocations;

@end
