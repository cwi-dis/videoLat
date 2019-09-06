//
//  NetworkRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "NetworkRunManager.h"
#import "AppDelegate.h"
#import "MachineDescription.h"
#import "NetworkIODevice.h"
#import "EventLogger.h"

///
/// How many times do we want to get a message that the prerun code has been detected?
/// This define is used on the master side, and stops the prerun sequence. It should be high enough that we
/// have a reasonable measurement of the RTT and the clock difference.
#define PREPARE_COUNT 32


///
/// What is the maximum time we try to detect a QR-code (in microseconds)?
/// This define is used on the master side, to trigger a new QR code if the old one was never detected, for some reason.
#define MAX_DETECTION_INTERVAL 5000000LL

@implementation NetworkRunManager
@synthesize selectionView;
@synthesize outputView;
@dynamic clock;

+ (void)initialize
{
    // We register ourselves for receive-only or transmit-only, as a helper. At the very least we must make
    // sure the nibfiles are registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"QR Code Camera Helper"];
    [BaseRunManager registerNib: @"RemoteHelperCamera" forMeasurementType: @"QR Code Camera Helper"];
    [BaseRunManager registerClass: [self class] forMeasurementType: @"QR Code Screen Helper"];
    [BaseRunManager registerNib: @"RemoteHelperScreen" forMeasurementType: @"QR Code Screen Helper"];
#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"QR Code Camera Helper"];
    [BaseRunManager registerSelectionNib: @"NetworkInputSelectionView" forMeasurementType: @"QR Code Screen Helper"];
#endif
}

- (NetworkRunManager *) init
{
    self = [super init];
    if (self) {
        codeRequested = nil;
    }
    return self;
}

- (void) dealloc
{
    
}

- (void) awakeFromNib
{
    networkHelper = YES;
    assert(self.networkIODevice);
    [super awakeFromNib];
}

- (void)codeRequestedByMaster: (NSString *)code
{
    assert(self.capturer == self.networkIODevice);
    codeRequested = code;
    [self triggerNewOutputValueAfterDelay];
}

- (NSString *)getNewOutputCode
{
    if (codeRequested) {
        NSString *rv = codeRequested;
        return rv;
    }
    return [super getNewOutputCode];
}

- (void)newOutputDoneAt: (uint64_t)timestamp
{
    if (codeRequested) {
        assert(self.networkIODevice);
        if ([codeRequested isEqualToString:codeReported]) return;
        [self.networkIODevice reportTransmission:codeRequested at:timestamp];
        codeReported = codeRequested;
    } else {
        if (self.capturer == self.networkIODevice) {
            // We are an output-only helper. Get ready for a new display.
            [self triggerNewOutputValueAfterDelay];
        }
    }
}

- (void)triggerNewOutputValue
{
    if (self.capturer != self.networkIODevice) {
        // We handle input, not output. Nothing to trigger.
        return;
    }
    [super triggerNewOutputValue];
}

- (BOOL) prepareInputDevice
{
    BOOL ok = [super prepareInputDevice];
    if (!ok) return NO;
    if (self.networkIODevice && self.networkIODevice != self.capturer) {
        // If we have a network connection and this network connection is _not_
        // the input device we assume it is a camera and we start capturing, so we
        // can detect the QR-code containing the IP address and port.
        ok = [self reportInputDeviceToRemote];
        if (!ok) return NO;
        [self.capturer startCapturing:YES];
    }
    return YES;
}

- (BOOL) prepareOutputDevice
{
    BOOL ok = [super prepareOutputDevice];
    if (!ok) return NO;
    if (self.networkIODevice && self.networkIODevice == self.capturer) {
        // Only do this for helper output devices....
        ok = [self reportOutputDeviceToRemote];
    }
    return ok;
}


- (BOOL)reportInputDeviceToRemote
{
    DeviceDescription *deviceDescriptorToSend = nil;
    if (self.measurementType.isCalibration) {
#ifdef WITH_APPKIT
        if (self.selectionView) assert(self.selectionView.bBase == nil);
#endif
        assert(self.capturer);
        deviceDescriptorToSend = [[DeviceDescription alloc] initFromInputDevice: self.capturer];
    } else {
#ifdef WITH_APPKIT
        assert(self.selectionView);
        baseName = self.selectionView.baseName;
#endif
        if (baseName == nil) {
            NSLog(@"NetworkRunManager: baseName == nil");
            return NO;
        }
        MeasurementType *baseType;
        baseType = (MeasurementType *)self.measurementType.requires;
        MeasurementDataStore *baseStore = [baseType measurementNamed: baseName];
        assert(baseStore.input);
        deviceDescriptorToSend = [[DeviceDescription alloc] initFromCalibrationInput: baseStore];
    }
    [self.networkIODevice reportInputDevice: deviceDescriptorToSend];
    return YES;
}

- (BOOL)reportOutputDeviceToRemote
{
    DeviceDescription *deviceDescriptorToSend = nil;
    if (self.measurementType.isCalibration) {
        assert(self.outputView);
        deviceDescriptorToSend = [[DeviceDescription alloc] initFromOutputDevice: self.outputView];
    } else {
#ifdef WITH_APPKIT
        assert(self.selectionView);
        baseName = self.selectionView.baseName;
#endif
        if (baseName == nil) {
            NSLog(@"NetworkRunManager: baseName == nil");
            return NO;
        }
        MeasurementType *baseType;
        baseType = (MeasurementType *)self.measurementType.requires;
        MeasurementDataStore *baseStore = [baseType measurementNamed: baseName];
        assert(baseStore.output);
        deviceDescriptorToSend = [[DeviceDescription alloc] initFromCalibrationOutput: baseStore];
    }
    assert(self.networkIODevice);
    [self.networkIODevice reportOutputDevice: deviceDescriptorToSend];
    return YES;
}

- (void)reportHeartbeat
{
    assert(self.networkIODevice);
    [self.networkIODevice reportHeartbeat];
}

- (void)receivedMeasurementResult: (MeasurementDataStore *)result
{
    if (self.capturer) [self.capturer stop];
    if (self.completionHandler) {
        [self.completionHandler performSelectorOnMainThread:@selector(openUntitledDocumentWithMeasurement:) withObject:result waitUntilDone:NO];
    } else {
#ifdef WITH_APPKIT
        AppDelegate *d = (AppDelegate *)[[NSApplication sharedApplication] delegate];
        [d performSelectorOnMainThread:@selector(openUntitledDocumentWithMeasurement:) withObject:result waitUntilDone:NO];
        [self.statusView.window close];
#else
        assert(0);
#endif
    }
}

@end
