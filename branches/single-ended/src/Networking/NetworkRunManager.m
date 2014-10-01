//
//  NetworkRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "NetworkRunManager.h"
@implementation NetworkRunManager

+ (void)initialize
{
    // Unsure whether we need to register our class?
#if 0
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Networking"];
    // No nib is registered...
#endif
#if 0
    // We also register ourselves for send-only, as a slave. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Transmission (Master/Server)"];
    [BaseRunManager registerNib: @"MasterSenderRun" forMeasurementType: @"Video Transmission (Master/Server)"];
#endif
    // We also register ourselves for receive-only, as a slave. At the very least we must make
    // sure the nibfile is registered...
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Video Reception (Slave/Client)"];
    [BaseRunManager registerNib: @"SlaveReceiverRun" forMeasurementType: @"Video Reception (Slave/Client)"];
}

#if 0
- (NetworkRunManager *) init
{
    self = [super init];
    if (self) {
        handlesInput = NO;
        handlesOutput = NO;
    }
    return self;
}

- (void)terminate
{
	BaseRunManager *ic = self.inputCompanion, *oc = self.outputCompanion;
	self.inputCompanion = nil;
	self.outputCompanion = nil;
	if (ic) [ic terminate];
	if (oc) [oc terminate];
	self.collector = nil;
	self.statusView = nil;
	self.measurementMaster = nil;
	
}

- (void) dealloc
{
}

- (void) awakeFromNib
{
    NSString *errorMessage = nil;
    handlesInput = self.inputCompanion == nil;
    handlesOutput = self.outputCompanion == nil;
    if (handlesInput && handlesOutput) {
        // This run manager is responsible for both input and output
        self.inputCompanion = self;
        self.outputCompanion = self;
    }
    if (handlesInput) {
        // We handle only input. Assert output handler exists and points back to us
        if (self.outputCompanion.inputCompanion != self) {
            errorMessage = [NSString stringWithFormat:@"Programmer error: %@ has outputCompanion %@ but it has inputCompanion %@",
                            self, self.outputCompanion, self.outputCompanion.inputCompanion];
        }
    }
    if (handlesOutput) {
        // We handle only output. Assert input handler exists and points back to us
        if (self.inputCompanion.outputCompanion != self) {
            errorMessage = [NSString stringWithFormat:@"Programmer error: %@ has inputCompanion %@ but it has outputCompanion %@",
                            self, self.inputCompanion, self.inputCompanion.outputCompanion];
        }
    }
    if (errorMessage) {
        NSAlert *alert = [NSAlert alertWithMessageText: @"Internal error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", errorMessage];
        [alert runModal];
    }
}

- (void) selectMeasurementType:(NSString *)typeName
{
	measurementType = [MeasurementType forType:typeName];
    if (self.outputCompanion && self.outputCompanion != self)
        [self.outputCompanion selectMeasurementType: typeName];
    [self restart];
}
#endif

- (void)restart
{
    NSLog(@"NetworkRunManager.restart. Unsure what to do...");
}

- (void)stop
{
	[NSException raise:@"NetworkRunManager" format:@"Must override stop in subclass"];
}

- (void)triggerNewOutputValue
{
	[NSException raise:@"NetworkRunManager" format:@"Must override triggerNewOutputValue in subclass"];
}

- (CIImage *)newOutputStart
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newOutputStart in subclass"];
	return nil;
}

- (void)newOutputDone
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newOutputDone in subclass"];
}

- (void)setFinderRect: (NSRect)theRect
{
	[NSException raise:@"NetworkRunManager" format:@"Must override setFinderRect in subclass"];
}


- (void)newInputStart
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newInputStart in subclass"];
}

- (void)newInputStart: (uint64_t)timestamp
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newInputStart: in subclass"];
}


- (void)newInputDone
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newInputDone in subclass"];
}


- (void) newInputDone: (void*)buffer
    width: (int)w
    height: (int)h
    format: (const char*)formatStr
    size: (int)size
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newInputDone in subclass"];
}

- (void)newInputDone: (void*)buffer
                size: (int)size
            channels: (int)channels
                  at: (uint64_t)timestamp
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newInputDone in subclass"];
}
@end
