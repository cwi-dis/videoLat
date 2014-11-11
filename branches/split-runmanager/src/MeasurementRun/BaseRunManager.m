//
//  BaseRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "BaseRunManager.h"

static NSMutableDictionary *runManagerClasses;
static NSMutableDictionary *runManagerNibs;

@implementation BaseRunManager

@synthesize running;
@synthesize preRunning;

+ (void)initialize
{
    runManagerClasses = [[NSMutableDictionary alloc] initWithCapacity:10];
    runManagerNibs = [[NSMutableDictionary alloc] initWithCapacity:10];
}

+ (void)registerClass: (Class)managerClass forMeasurementType: (NSString *)name
{
    // XXXJACK assert it is a subclass of BaseRunManager
    Class oldClass = [runManagerClasses objectForKey:name];
    if (oldClass != nil && oldClass != managerClass) {
        NSLog(@"BaseRunManager: attempt to set class for %@ to %@ but ist was already set to %@\n", name, managerClass, oldClass);
        abort();
    }
    if (VL_DEBUG) NSLog(@"BaseRunManager: Register %@ for %@\n", managerClass, name);
    [runManagerClasses setObject:managerClass forKey:name];
}

+ (Class)classForMeasurementType: (NSString *)name
{
    return [runManagerClasses objectForKey:name];
}

+ (void)registerNib: (NSString*)nibName forMeasurementType: (NSString *)name
{
    NSString *oldNib = [runManagerNibs objectForKey:name];
    if (oldNib != nil && oldNib != nibName) {
        NSLog(@"BaseRunManager: attempt to set Nib for %@ to %@ but it was already set to %@\n", name, nibName, oldNib);
        abort();
    }
    if (VL_DEBUG) NSLog(@"BaseRunManager: Register %@ for %@\n", nibName, name);
    [runManagerNibs setObject:nibName forKey:name];
}

+ (NSString *)nibForMeasurementType: (NSString *)name
{
    return [runManagerNibs objectForKey:name];
}

@synthesize measurementType;

- (BaseRunManager *) init
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
    NSObject<RunInputManagerProtocol> *ic = self.inputCompanion;
    NSObject<RunOutputManagerProtocol> *oc = self.outputCompanion;
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
	self.measurementType = [MeasurementType forType:typeName];
    assert(handlesInput);
    [self restart];
    if (!handlesOutput) {
        [self.outputCompanion companionRestart];
    }
}

- (IBAction)deviceChanged: (id) sender
{
	NSLog(@"BaseRunManager: device changed");
}

- (BOOL)companionStartPreMeasuring
{
    self.preRunning = YES;
    return YES;
}

- (void)companionStopPreMeasuring
{
    assert(self.preRunning);
    self.preRunning = NO;
}

- (void)companionStartMeasuring
{
    self.running = YES;
}

- (void)companionStopMeasuring
{
    self.running = NO;
}

- (void)restart
{
	[NSException raise:@"BaseRunManager" format:@"Must override restart in subclass %@", [self class]];
}

- (void)companionRestart
{
	[NSException raise:@"BaseRunManager" format:@"Must override companionRestart in subclass %@", [self class]];
}

- (void)stop
{
	[NSException raise:@"BaseRunManager" format:@"Must override stop in subclass %@", [self class]];
}

- (void)triggerNewOutputValue
{
	[NSException raise:@"BaseRunManager" format:@"Must override triggerNewOutputValue in subclass %@", [self class]];
}

- (CIImage *)newOutputStart
{
	[NSException raise:@"BaseRunManager" format:@"Must override newOutputStart in subclass %@", [self class]];
	return nil;
}

- (void)newOutputDone
{
	[NSException raise:@"BaseRunManager" format:@"Must override newOutputDone in subclass %@", [self class]];
}

- (void)setFinderRect: (NSRect)theRect
{
	[NSException raise:@"BaseRunManager" format:@"Must override setFinderRect in subclass %@", [self class]];
}


- (void)newInputStart
{
	[NSException raise:@"BaseRunManager" format:@"Must override newInputStart in subclass %@", [self class]];
}

- (void)newInputStart: (uint64_t)timestamp
{
	[NSException raise:@"BaseRunManager" format:@"Must override newInputStart: in subclass %@", [self class]];
}


- (void)newInputDone
{
	[NSException raise:@"BaseRunManager" format:@"Must override newInputDone in subclass %@", [self class]];
}

- (void) newInputDone: (NSString *)data count: (int)count at: (uint64_t) timestamp
{
    [NSException raise:@"BaseRunManager" format:@"Must override newInputDone:count:at in subclass %@", [self class]];
}


- (void) newInputDone: (void*)buffer
    width: (int)w
    height: (int)h
    format: (const char*)formatStr
    size: (int)size
{
	[NSException raise:@"BaseRunManager" format:@"Must override newInputDone:width:height:format:size in subclass %@", [self class]];
}

- (void)newInputDone: (void*)buffer
                size: (int)size
            channels: (int)channels
                  at: (uint64_t)timestamp
{
	[NSException raise:@"BaseRunManager" format:@"Must override newInputDone:buffer:size:channels:at in subclass %@", [self class]];
}

- (NSString *)genPrerunCode
{
    return nil;
}
@end
