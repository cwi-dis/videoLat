//
//  HardwareRunManager.h
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "BaseRunManager.h"

@interface HardwareRunManager : BaseRunManager <ClockProtocol> {
    BOOL alive; // True if the class is alive and the periodic timer should run
    BOOL connected; // True if the hardware device is connected
    
    double outputLevel; // Current output light level
    uint64_t outputTimestamp;
    BOOL triggerNewOutputValue;
    
    double inputLevel;  // Current input pight level
    double minInputLevel;
    double maxInputLevel;
    uint64_t inputTimestamp;
    
    int prerunMoreNeeded;
}

@property(weak) IBOutlet NSButton *bPreRun;
@property(weak) IBOutlet NSButton *bRun;
@property(weak) IBOutlet NSButton *bDeviceConnected;
@property(weak) IBOutlet NSButton *bOutputValue;
@property(weak) IBOutlet NSButton *bInputValue;
@property(weak) IBOutlet NSTextField *bInputNumericValue;
@property(weak) IBOutlet id <ClockProtocol> clock;
@property(weak) IBOutlet id <HardwareLightProtocol> device;

+ (void)initialize;
- (HardwareRunManager *)init;
-(void)stop;

- (void)_periodic: (id)sender;
- (void)_update: (id)sender;

- (IBAction)startPreMeasuring: (id)sender;
- (IBAction)stopPreMeasuring: (id)sender;
- (IBAction)startMeasuring: (id)sender;

#if 0
- (void)_triggerNewOutputValue;
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
