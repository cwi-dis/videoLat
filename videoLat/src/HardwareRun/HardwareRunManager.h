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
/// This class works closely together with HardwareLightProtocol, and actually with
/// its only current implementation, LabJackDevice. Testing with other hardware and
/// allowing selection of input and output device has not been implemented.
///
/// When compared to the other run manager this class also implements the input and
/// selection view object functionality. Should be fixed at some point.
///
@interface HardwareRunManager : BaseRunManager {

    NSString *prevInputCode;    //!< Last input code detected
    int prevInputCodeDetectionCount;    //!< How often prevInputCode was detected
}

@property(weak) IBOutlet HardwareOutputView *outputView;    //!< Assigned in NIB: visual feedback view of output for the user
@property(weak) IBOutlet NSObject <ClockProtocol> *clock;   //!< Assigned in NIB: clock source

+ (void)initialize;
- (HardwareRunManager *)init;   //!< Initializer

- (IBAction)stopPreMeasuring: (id)sender;

- (void)triggerNewOutputValue;

// InputDeviceProtocol
- (void) startCapturing: (BOOL)showPreview;
- (void) stopCapturing;

@end
