///
///  @file HardwareInput.h
///  @brief Video camera driver using AVFoundation.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//
#import "protocols.h"
#import "BaseRunManager.h"
#import "LevelStatusView.h"

///
/// Class that implements InputDeviceProtocol (and ClockProtocol) for hardware input.
///
@interface HardwareInput : NSObject <ClockProtocol, InputDeviceProtocol> {
    BOOL alive;                 //!< True when the _periodic method should run
    BOOL connected;             //!< True if the hardware device is connected
    NSString *lastError;        //!< Last error message from device
	BOOL capturing;				//!< True when capturing

    uint64_t outputTimestamp;   //!< When the last output light level change was made
    BOOL newOutputValueWanted;  //!< True if we need to change the output light level
    BOOL reportNewOutput;       //!< True if we need to call the manager when the new output value was shown
	NSString *outputCode;		//!< Current output code
	double outputLevel;			//!< Current output light level

    NSString *prevInputCode;    //!< Last input code detected
    int prevInputCodeDetectionCount;    //!< How often prevInputCode was detected
    double inputLevel;          //!< Current input light level
    double minInputLevel;       //!< Lowest analog input level seen
    double maxInputLevel;       //!< Highest analog input level seen
    uint64_t inputTimestamp;    //!< When inputLevel was measured
}
@property(weak) IBOutlet BaseRunManager *manager;           //!< Our input manager
@property(weak) IBOutlet BaseRunManager *outputManager;     //!< Our output manager, if different
@property(weak) IBOutlet NSObject<ClockProtocol> *clock;    //!< Our clock, if not ourselves
@property(weak) IBOutlet LevelStatusView *levelStatusView;  //!< Assigned in NIB: visual feedback on light level detected
@property(weak) IBOutlet NSTextField *bDriverStatus;        //!< Indicator for the user that the selected device works
@property(weak) IBOutlet NSStepper *bSamplePeriodStepper;	//!< UI element for samplePeriodMs
@property(weak) IBOutlet NSTextField *bSamplePeriodValue;	//!< UI element for samplePeriodMs

@property(nonatomic,readwrite) int samplePeriodMs;			//!< How often we sample the hardware
@property NSObject <HardwareLightProtocol> *device;         //!< Hardware device handler

- (IBAction)periodChanged: (id) sender;	//!< Action message for samplePeriodMs UI elements

- (uint64_t)now;

- (bool)available;
- (NSArray*) deviceNames;

- (BOOL)switchToDeviceWithName: (NSString *)name;
- (void)_switchToDevice: (NSString *)selectedDevice;

- (void) startCapturing: (BOOL) showPreview;
- (void) pauseCapturing: (BOOL) pause;
- (void) stopCapturing;

- (void) stop;
- (void) restart;

- (void) setOutputCode: (NSString *)code report: (BOOL)report;

- (void)_updatePeriod;	//!< Internal: update UI to show samplePeriodMs.
///
/// The worker thread.
/// Once every millisecond (at most) it calls the light method on the device to
/// set the output light level and read the input light level.
/// Calls _update on the main thread if anything has changed.
///
- (void)_periodic: (id)sender;
///
/// Act on changes in input and output levels. Updates the UI, calls collector methods
/// to record reception and transmission, triggers a new output value when needed.
///
- (void)_update: (id)sender;

@end
