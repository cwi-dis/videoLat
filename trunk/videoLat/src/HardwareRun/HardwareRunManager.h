//
//  HardwareRunManager.h
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "BaseRunManager.h"
#import "HardwareOutputView.h"

///
/// A Subclass of BaseRunManager geared towards doing hardware-assisted video
/// measurements. It works together with an object implementing the low-level
/// HardwareLightProtocol to generate light/no light conditions and detect them.
///
@interface HardwareRunManager : BaseRunManager <ClockProtocol> {
    BOOL alive; // True if the class is alive and the periodic timer should run
    BOOL connected; // True if the hardware device is connected
	BOOL inErrorMode; // True if we have displayed an error message
    
    double outputLevel; // Current output light level
    uint64_t outputTimestamp;
    BOOL newOutputValueWanted;
    
    double inputLevel;  // Current input pight level
    double minInputLevel;
    double maxInputLevel;
    uint64_t inputTimestamp;
    
    int prerunMoreNeeded;
}

@property(weak) IBOutlet NSButton *bPreRun;
@property(weak) IBOutlet NSButton *bRun;
@property(weak) IBOutlet NSButton *bDeviceConnected;
@property(weak) IBOutlet NSPopUpButton *bBase;
@property(weak) IBOutlet HardwareOutputView *outputView;
@property(weak) IBOutlet NSButton *bInputValue;
@property(weak) IBOutlet NSTextField *bInputNumericValue;
@property(weak) IBOutlet NSObject <ClockProtocol> *clock;
@property(weak) IBOutlet NSObject <HardwareLightProtocol> *device;

+ (void)initialize;
- (HardwareRunManager *)init;
-(void)stop;

- (void)_periodic: (id)sender;
- (void)_update: (id)sender;

- (IBAction)startPreMeasuring: (id)sender;
- (IBAction)stopPreMeasuring: (id)sender;
- (IBAction)startMeasuring: (id)sender;

- (void)triggerNewOutputValue;
#if 0
- (void) _prerunRecordNoReception;
- (void) _prerunRecordReception: (NSString *)code;
#endif

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

@end
