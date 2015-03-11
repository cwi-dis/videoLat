//
//  MachineDescription.h
//  videoLat
//
//  Created by Jack Jansen on 2/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MachineDescription : NSObject

+ (MachineDescription *)thisMachine;			//!< Return singleton object describing the current machine

@property(readonly) NSString *machineID;		//!< Unique identifier of this computer
@property(readonly) NSString *machineName;		//!< Human-readable name of this computer
@property(readonly) NSString *machineTypeID;	//!< Unique identifier of this computer model

@end
