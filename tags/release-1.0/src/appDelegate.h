//
//  appDelegate.h
//  videoLat
//
//  Created by Jack Jansen on 22-11-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>
#import "protocols.h"
#import "MeasurementType.h"

@interface appDelegate : NSObject <CLLocationManagerDelegate>{
}
@property(strong) MeasurementType *measurementTypes;
@property(strong) CLLocationManager *locationManager;
@property(strong) NSString *location;

- (NSURL *)directoryForCalibrations;
- (void)_loadCalibrationsFrom: (NSURL *)directory;
- (BOOL)_loadCalibration: (NSURL *)directory error: (NSError **)outError;
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
- (IBAction)openWebsite:(id)sender;
- (IBAction)openCalibrationFolder:(id)sender;
@end
