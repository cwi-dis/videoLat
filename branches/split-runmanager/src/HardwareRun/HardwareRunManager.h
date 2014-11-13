//
//  HardwareRunManager.h
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "BaseRunManager.h"
#import "HardwareOutputView.h"
#import "HardwareSelectionView.h"

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
@interface HardwareRunManager : BaseRunManager <ClockProtocol, InputCaptureProtocol> {
    BOOL alive;                 //!< True when the _periodic method should run
    BOOL connected;             //!< True if the hardware device is connected
    NSString *lastError;        //!< Last error message from device
    
    double outputLevel;         //!< Current output light level
    uint64_t outputTimestamp;   //!< When the last output light level change was made
    BOOL newOutputValueWanted;  //!< True if we need to change the output light level
    
    double inputLevel;          //!< Current input light level
    double minInputLevel;       //!< Lowest analog input level seen
    double maxInputLevel;       //!< Highest analog input level seen
    uint64_t inputTimestamp;    //!< When inputLevel was measured
}

@property(weak) IBOutlet NSButton *bConnected;              //!< Indicator for the user that the selected device works
@property(weak) IBOutlet NSButton *bInputValue;             //!< UI element: feedback on light/no light detected
@property(weak) IBOutlet NSTextField *bInputNumericValue;   //!< UI element: feedback on analog input received
@property(weak) IBOutlet HardwareSelectionView *selectionView;  //!< Assigned in NIB: hardware device selector
@property(weak) IBOutlet HardwareOutputView *outputView;    //!< Assigned in NIB: visual feedback view of output for the user
@property(weak) IBOutlet NSObject <ClockProtocol> *clock;   //!< Assigned in NIB: clock source
@property (readonly) NSString* deviceID;					//!< Unique string that identifies the input device
@property (readonly) NSString* deviceName;					//!< Human-readable string that identifies the input device

@property NSObject <HardwareLightProtocol> *device;         //!< Hardware device handler

+ (void)initialize;
- (HardwareRunManager *)init;   //!< Initializer
-(void)stop;

- (void)_switchToDevice: (NSString *)selectedDevice;
- (IBAction)selectBase: (id)sender;     //!< Called when the user selects a different base measurement
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

- (IBAction)stopPreMeasuring: (id)sender;   //!< Internal: stop pre-measuring because we have heard enough

- (void)triggerNewOutputValue;

// MeasurementOutputManagerProtocol
- (CIImage *)newOutputStart;
- (void)newOutputDone;

// MeasurementInputManagerProtocol
- (void)restart;
- (void)setFinderRect: (NSRect)theRect;
- (void)newInputStart:(uint64_t)timestamp;
- (void)newInputStart;
- (void)newInputDone;
- (void) newInputDone: (void*)buffer
                width: (int)w
               height: (int)h
               format: (const char*)formatStr
                 size: (int)size;

// InputCaptureProtocol
- (void) startCapturing: (BOOL)showPreview;
- (void) stopCapturing;

@end
