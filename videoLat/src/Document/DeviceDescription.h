///
///  @file DeviceDescription.h
///  @brief Holds DeviceDescription object definition.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
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
@property(strong) NSString* os;				   //!< Operating system
@property(strong) NSString* videoLatVersion;   //!< Version of videoLat that handled this device
@property(strong) NSString* deviceID;          //!< Unique ID identifying the input or output device type
@property(strong) NSString* device;            //!< Human readable name of the input or output device type
@property(strong) MeasurementDataStore* calibration;	//!< Optional calibration used for this device

/// Standard initializer, assigns only geolocation.
- (DeviceDescription *)init;

/// Initializer for sending DeviceDescription to remote location.
/// Initializes geolocation to here, and other fields from calibration input device.
- (DeviceDescription *)initFromCalibrationInput: (MeasurementDataStore *)_calibration;

/// Initializer for sending DeviceDescription to remote location.
/// Initializes geolocation to here, and other fields from calibration output device.
- (DeviceDescription *)initFromCalibrationOutput: (MeasurementDataStore *)_calibration;

/// Initializer for sending DeviceDescription to remote location.
/// Initialize everything from input device
- (DeviceDescription *)initFromInputDevice: (id<InputDeviceProtocol>)inputDevice;

/// Initializer for output-only calibrations
/// Initialize everything from output device
- (DeviceDescription *)initFromOutputDevice: (id<OutputDeviceProtocol>)inputDevice;

/// Get name for device.
/// Adds hardware type name if this measurrement was taken on differrent hardware than this one.
- (NSString *)nameForDevice;

@end
