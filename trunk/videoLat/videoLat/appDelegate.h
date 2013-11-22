//
//  appDelegate.h
//  videoLat
//
//  Created by Jack Jansen on 22-11-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"
#import "MeasurementType.h"

@interface appDelegate : NSObject {
}
@property(retain) MeasurementType *measurementTypes;

- (NSURL *)directoryForCalibrations;
- (void)_loadCalibrationsFrom: (NSURL *)directory;
@end
