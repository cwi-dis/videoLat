//
//  OutputManager.h
//
//  Created by Jack Jansen on 27-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"
#import "BaseRunManager.h"
#import "AudioSelectionView.h"
#import "AudioOutputView.h"

@interface AudioRunManager : BaseRunManager {
    
}
//@property(weak) IBOutlet NSPopUpButton *bBase;
@property(weak) IBOutlet AudioOutputView *outputView;
@property(weak) IBOutlet NSLevelIndicator *bInputValue;
@property(weak) IBOutlet AudioSelectionView *selectionView;
@property(weak) IBOutlet id <InputCaptureProtocol> capturer;
@property(weak) IBOutlet id <ClockProtocol> clock;

+ (void)initialize;
- (AudioRunManager *)init;
- (void)stop;

- (IBAction)startPreMeasuring: (id)sender;
- (IBAction)stopPreMeasuring: (id)sender;
- (IBAction)startMeasuring: (id)sender;

- (void)triggerNewOutputValue;
//- (void) _prerunRecordNoReception;
//- (void) _prerunRecordReception: (NSString *)code;

// MeasurementOutputManagerProtocol
- (CIImage *)newOutputStart;
- (void)newOutputDone;

#if 0
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
#endif
@end
