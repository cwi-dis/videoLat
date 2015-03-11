//
//  DeviceDescription.h
//  videoLat
//
//  Created by Jack Jansen on 2/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "protocols.h"

@class MeasurementDataStore;

@interface DeviceDescription : NSObject {
};
@property(strong) NSString* location;          //!< Metadata variable, set by owner
@property(strong) NSString* machineTypeID;     //!< Metadata variable, set by owner
@property(strong) NSString* machineID;         //!< Metadata variable, set by owner
@property(strong) NSString* machine;           //!< Metadata variable, set by owner
@property(strong) NSString* deviceID;          //!< Metadata variable, set by owner
@property(strong) NSString* device;            //!< Metadata variable, set by owner
@property(strong) MeasurementDataStore* calibration;

/// Standard initializer, assigns only geolocation.
- (DeviceDescription *)init;

/// Initializer for sending DeviceDescription to remote location.
/// Initializes geolocation to here, and other fields from calibration input device.
- (DeviceDescription *)initFromCalibrationInput: (MeasurementDataStore *)_calibration;
/// Initializer for sending DeviceDescription to remote location.
/// Initialize everything from input device
- (DeviceDescription *)initFromInputDevice: (id<InputCaptureProtocol>)inputDevice;
/// Initializer for output-only calibrations
/// Initialize everything from output device
- (DeviceDescription *)initFromOutputDevice: (id<OutputViewProtocol>)inputDevice;
@end
