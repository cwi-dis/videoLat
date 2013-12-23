//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "HardwareRunManager.h"
#import "PythonLoader.h"

@implementation HardwareRunManager
+ (void) initialize
{
    [BaseRunManager registerClass: [self class] forMeasurementType: @"Hardware Calibrate"];
    [BaseRunManager registerNib: @"HardwareRunManager" forMeasurementType: @"Hardware Calibrate"];
    PythonLoader *pl = [PythonLoader sharedPythonLoader];
    [pl loadScriptNamed:@"LabJackDevice"];
}

- (HardwareRunManager*)init
{
    self = [super init];
	if (self) {
	}
    return self;
}

- (void)awakeFromNib
{
    if (self.device == nil)
        NSLog(@"HardwareRunManager: no hardware device available");
}

- (IBAction)startPreMeasuring: (id)sender
{
	[NSException raise:@"HardwareRunManager" format:@"Must override startPreMeasuring in subclass"];
}

- (IBAction)stopPreMeasuring: (id)sender
{
	[NSException raise:@"HardwareRunManager" format:@"Must override startPreMeasuring in subclass"];
}

- (IBAction)startMeasuring: (id)sender
{
	[NSException raise:@"HardwareRunManager" format:@"Must override startMeasuring in subclass"];
}

- (void)restart
{
	[NSException raise:@"HardwareRunManager" format:@"Must override restart in subclass"];
}

- (void)stop
{
	[NSException raise:@"HardwareRunManager" format:@"Must override stop in subclass"];
}

- (CIImage *)newOutputStart
{
	[NSException raise:@"HardwareRunManager" format:@"Must override newOutputStart in subclass"];
	return nil;
}

- (void)newOutputDone
{
	[NSException raise:@"HardwareRunManager" format:@"Must override newOutputDone in subclass"];
}

- (void)setFinderRect: (NSRect)theRect
{
	[NSException raise:@"HardwareRunManager" format:@"Must override setFinderRect in subclass"];
}


- (void)newInputStart
{
	[NSException raise:@"HardwareRunManager" format:@"Must override newInputStart in subclass"];
}

- (void)newInputStart: (uint64_t)timestamp
{
	[NSException raise:@"HardwareRunManager" format:@"Must override newInputStart: in subclass"];
}


- (void)newInputDone
{
	[NSException raise:@"HardwareRunManager" format:@"Must override newInputDone in subclass"];
}


- (void) newInputDone: (void*)buffer
                width: (int)w
               height: (int)h
               format: (const char*)formatStr
                 size: (int)size
{
	[NSException raise:@"HardwareRunManager" format:@"Must override newInputDone in subclass"];
}
@end
