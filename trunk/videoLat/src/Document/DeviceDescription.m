//
//  DeviceDescription.m
//  videoLat
//
//  Created by Jack Jansen on 2/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "DeviceDescription.h"
#import "AppDelegate.h"
#import "MachineDescription.h"

@implementation DeviceDescription
@synthesize location;
@synthesize machineTypeID;
@synthesize machineID;
@synthesize machine;
@synthesize deviceID;
@synthesize device;
@synthesize calibration;

- (DeviceDescription *)init
{
	self = [super init];
	self.location = ((AppDelegate *)[[NSorUIApplication sharedApplication] delegate]).location;
	return self;
}

- (DeviceDescription *)initFromCalibrationInput:(MeasurementDataStore *)_calibration
{
	self = [super init];
	if (self == nil) return nil;
	self.location = ((AppDelegate *)[[NSorUIApplication sharedApplication] delegate]).location;
	self.machineTypeID = _calibration.input.machineTypeID;
	self.machineID = _calibration.input.machineID;
	self.machine = _calibration.input.machine;
	self.deviceID = _calibration.input.deviceID;
	self.device = _calibration.input.device;
	self.calibration = _calibration;
	return self;
}

- (DeviceDescription *)initFromInputDevice: (id<InputCaptureProtocol>)inputDevice
{
    self = [super init];
    if (self == nil) return nil;
    
    MachineDescription *md = [MachineDescription thisMachine];
    self.location = ((AppDelegate *)[[NSorUIApplication sharedApplication] delegate]).location;
    self.machineID = md.machineID;
    self.machine = md.machineName;
    self.machineTypeID = md.machineTypeID;
    self.device = inputDevice.deviceName;
    self.deviceID = inputDevice.deviceID;
    self.calibration = nil;
    return self;
}

- (DeviceDescription *)initFromOutputDevice: (id<OutputViewProtocol>)outputDevice
{
    self = [super init];
    if (self == nil) return nil;
    
    MachineDescription *md = [MachineDescription thisMachine];
    self.location = ((AppDelegate *)[[NSorUIApplication sharedApplication] delegate]).location;
    self.machineID = md.machineID;
    self.machine = md.machineName;
    self.machineTypeID = md.machineTypeID;
    self.device = outputDevice.deviceName;
    self.deviceID = outputDevice.deviceID;
    self.calibration = nil;
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
	if (self == nil) return nil;
    location = [coder decodeObjectForKey:@"location"];
    machineTypeID = [coder decodeObjectForKey:@"machineTypeID"];
    machineID = [coder decodeObjectForKey:@"machineID"];
    machine = [coder decodeObjectForKey:@"machine"];
    deviceID = [coder decodeObjectForKey: @"deviceID"];
    device = [coder decodeObjectForKey: @"device"];
    calibration = [coder decodeObjectForKey: @"calibration"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:location forKey: @"location"];
    [coder encodeObject:machineTypeID forKey: @"machineTypeID"];
    [coder encodeObject:machineID forKey: @"machineID"];
    [coder encodeObject:machine forKey: @"machine"];
    [coder encodeObject:deviceID forKey: @"deviceID"];
    [coder encodeObject:device forKey: @"device"];
    [coder encodeObject: calibration forKey: @"calibration"];
}

- (NSString *)nameForDevice
{
    MachineDescription *md = [MachineDescription thisMachine];
	if (![machineTypeID isEqualToString: md.machineTypeID]) {
		return [NSString stringWithFormat:@"%@ on %@", device, machineTypeID];
	}
	return device;
}
@end

