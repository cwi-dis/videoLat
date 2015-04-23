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

///
/// Object to store description of an input or output device.
///
@interface DeviceDescription : NSObject {
};
@property(strong) NSString* location;          //!< GPS location where this device was during measurement
@property(strong) NSString* machineTypeID;     //!< Unique ID identifying hardware machine type
@property(strong) NSString* machineID;         //!< Unique ID identifying the hardware machine itself
@property(strong) NSString* machine;           //!< Human readable name of the machine
@property(strong) NSString* deviceID;          //!< Unique ID identifying the input or output device type
@property(strong) NSString* device;            //!< Human readable name of the input or output device type
@property(strong) MeasurementDataStore* calibration;	//!< Optional calibration used for this device

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

/// Get name for device.
/// Adds hardware type name if this measurrement was taken on differrent hardware than this one.
- (NSString *)nameForDevice;

@end
