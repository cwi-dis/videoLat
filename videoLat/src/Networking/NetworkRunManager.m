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
#if 0
    // We also register ourselves for send-only, as a slave. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"QR Code Transmission"];
    [BaseRunManager registerNib: @"RemoteSlaveScreen" forMeasurementType: @"QR Code Transmission"];
    // We register ourselves for receive-only, as a slave. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"QR Code Reception"];
    [BaseRunManager registerNib: @"RemoteSlaveCamera" forMeasurementType: @"QR Code Reception"];

    [BaseRunManager registerClass: [self class] forMeasurementType: @"Reception Calibrate using Other Device"];
    [BaseRunManager registerNib: @"CalibrateCameraFromRemoteScreen" forMeasurementType: @"Reception Calibrate using Other Device"];
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Transmission Calibrate using Other Device"];
    [BaseRunManager registerNib: @"CalibrateScreenFromRemoteCamera" forMeasurementType: @"Transmission Calibrate using Other Device"];

#ifdef WITH_UIKIT
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"QR Code Reception"];
    [BaseRunManager registerSelectionNib: @"VideoInputSelectionView" forMeasurementType: @"Reception Calibrate using Other Device"];
    [BaseRunManager registerSelectionNib: @"NetworkInputSelectionView" forMeasurementType: @"QR Code Transmission"];
    [BaseRunManager registerSelectionNib: @"NetworkInputSelectionView" forMeasurementType: @"Transmission Calibrate using Other Device"];
#endif
#endif
}

- (NetworkRunManager *) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    
}

- (void) awakeFromNib
{
    slaveHandler = YES;
    assert(self.networkIODevice);
    [super awakeFromNib];
}
@end
