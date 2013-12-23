//
//  HardwareRunManager.h
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "BaseRunManager.h"

@interface HardwareRunManager : BaseRunManager
@property(weak) IBOutlet NSButton *bDeviceConnected;
@property(weak) IBOutlet NSButton *bOutputValue;
@property(weak) IBOutlet NSButton *bInputValue;
@property(weak) IBOutlet NSTextField *bInputNumericValue;
@property(weak) IBOutlet id <ClockProtocol> clock;
@property(weak) IBOutlet id <HardwareLightProtocol> device;

+ (void)initialize;
- (HardwareRunManager *)init;
-(void)stop;

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
