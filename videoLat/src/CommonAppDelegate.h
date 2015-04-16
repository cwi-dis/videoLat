//
//  CommonAppDelegate.h
//  
//
//  Created by Jack Jansen on 13/03/15.
//
//

#import <CoreLocation/CoreLocation.h>
#import "MeasurementType.h"
#import "protocols.h"

@interface CommonAppDelegate : NSObject <CLLocationManagerDelegate> {
    NSMutableDictionary *uuidToURL;
}

@property(strong) MeasurementType *measurementTypes;

@property(strong) CLLocationManager *locationManager;

@property(strong) NSString *location;

- (void)initVideolat;   //!< Initialize the app, common to OSX and iOS.
- (NSURL *)directoryForCalibrations;    //!< Returns directory where calibration run documents should be stored/loaded.
- (void)_loadCalibrationsFrom: (NSURL *)directory;  //!< Internal helper for applicationWillFinishLaunching, loads all calibrations.
- (BOOL)_loadCalibration: (NSURL *)url error: (NSError **)outError;   //!< Helper for loadCalibrationsFrom, loads a single calibration.
- (BOOL)haveCalibration: (NSString *)uuid;
- (IBAction)openWebsite:(id)sender; //!< Method to be called when the user wants to view the videoLat website.

// Location manager delegate method:
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)newLocations;

@end
