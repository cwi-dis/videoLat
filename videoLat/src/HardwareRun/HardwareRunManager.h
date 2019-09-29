///
///  @file HardwareRunManager.h
///  @brief Subclass of BaseRunManager to do arduino/labjack assisted measurements.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "BaseRunManager.h"
#import "HardwareOutputView.h"
#import "protocols.h"
///
/// A Subclass of BaseRunManager geared towards doing hardware-assisted video
/// measurements. It works together with an object implementing the low-level
/// HardwareLightProtocol to generate light/no light conditions and detect them.
///
/// This class works closely together with HardwareLightProtocol, which is
/// implemented by various Python packages in HardwareDevices.
///
@interface HardwareRunManager : BaseRunManager {

}

@property(weak) IBOutlet HardwareOutputView *outputView;    //!< Assigned in NIB: visual feedback view of output for the user

+ (void)initialize;
- (HardwareRunManager *)init;   //!< Initializer

@end
