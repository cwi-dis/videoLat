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
@end
