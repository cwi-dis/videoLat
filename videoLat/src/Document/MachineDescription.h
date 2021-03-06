///
///  @file MachineDescription.h
///  @brief Holds MachineDescription object definition.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "compat.h"

///
/// Describes a computer (or iPhone or iPad).
///
@interface MachineDescription : NSObject

+ (MachineDescription *)thisMachine;			//!< Return singleton object describing the current machine.

@property(readonly) NSString *machineID;		//!< Unique identifier of this computer
@property(readonly) NSString *machineName;		//!< Human-readable name of this computer
@property(readonly) NSString *machineTypeID;	//!< Unique identifier of this computer model
@property(readonly) NSString *os;				//!< Name and version of operating system on this computer

@end
