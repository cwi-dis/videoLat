//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "HardwareRunManager.h"
#import "PythonLoader.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <mach/clock.h>

#define PRERUN_COUNT 200

@implementation HardwareRunManager
+ (void) initialize
{
    PythonLoader *pl = [PythonLoader sharedPythonLoader];
    BOOL hwfound = [pl loadScriptNamed:@"LabJackDevice"];
	if (hwfound) {
		[BaseRunManager registerClass: [self class] forMeasurementType: @"Hardware Calibrate"];
		[BaseRunManager registerNib: @"HardwareRunManager" forMeasurementType: @"Hardware Calibrate"];
		NSLog(@"HardwareLightProtocol = %@", @protocol(HardwareLightProtocol));
	}
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
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
	// Check that the Python script has loaded correctly
	if (self.device && ![self.device respondsToSelector: @selector(available)])
		self.device = nil;
    self.statusView = self.measurementMaster.statusView;
    self.collector = self.measurementMaster.collector;
    if (self.clock == nil) self.clock = self;
    [self restart];
}

- (uint64_t)now
{
    UInt64 machTimestamp = mach_absolute_time();
    Nanoseconds nanoTimestamp = AbsoluteToNanoseconds(*(AbsoluteTime*)&machTimestamp);
    uint64_t timestamp = *(UInt64 *)&nanoTimestamp;
    timestamp = timestamp / 1000;
    return timestamp;
}

- (void)_periodic: (id)sender
{
    BOOL first = YES;
    BOOL outputLevelChanged = NO;
    while(alive) {
        BOOL nConnected = self.device && [self.device available];
        uint64_t loopTimestamp = [self.clock now];
        @synchronized(self) {
            if (newOutputValueWanted) {
                outputTimestamp = loopTimestamp;
                outputLevel = 1-outputLevel;
                outputLevelChanged = YES;
                newOutputValueWanted = NO;
                if (1 || VL_DEBUG) NSLog(@"HardwareRunManager: outputLevel %f at %lld", outputLevel, outputTimestamp);
            }
        }
        double nInputLevel = [self.device light: outputLevel];
        
        @synchronized(self) {
			if (inputLevel < minInputLevel)
				minInputLevel = inputLevel;
			if (inputLevel > maxInputLevel)
				maxInputLevel = inputLevel;
            if (first || nConnected != connected || nInputLevel != inputLevel || outputLevelChanged) {
                connected = nConnected;
                inputLevel = nInputLevel;
                inputTimestamp = loopTimestamp;
                [self performSelectorOnMainThread:@selector(_update:) withObject:self waitUntilDone:NO];
                first = NO;
            }
        }
        outputLevelChanged = NO;
        [NSThread sleepForTimeInterval:0.001];
    }
}

- (void)_update: (id)sender
{
    @synchronized(self) {
        BOOL inputLight =(inputLevel > (maxInputLevel + minInputLevel)/2);
		BOOL outputMixed = (outputLevel == 0.5);
        BOOL outputLight = (outputLevel > 0.5);
        [self.bDeviceConnected setState: (connected ? NSOnState : NSOffState)];
        [self.bInputNumericValue setDoubleValue: inputLevel];
        [self.bInputValue setState: (inputLight ? NSOnState : NSOffState)];
        [self.outputView.bOutputValue setState: (outputMixed ? NSMixedState : outputLight ? NSOnState : NSOffState)];
        // Check for detections
        NSLog(@" inputLight %d outputLight %d outputMixed %d", inputLight, outputLight, outputMixed);
        if (inputLight == outputLight) {
            if (self.running) {
                if (1 || VL_DEBUG) NSLog(@"light %d transmitted %lld received %lld delta %lld", outputLight, outputTimestamp, inputTimestamp, inputTimestamp - outputTimestamp);
                [self.collector recordTransmission: outputLight? @"light": @"darkness" at:outputTimestamp];
                [self.collector recordReception:inputLight? @"light": @"darkness" at:inputTimestamp];
                self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
                self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
                [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
				[self.outputCompanion triggerNewOutputValue];
            } else if (self.preRunning) {
                prerunMoreNeeded--;
                self.statusView.detectCount = [NSString stringWithFormat: @"%d more", prerunMoreNeeded];
                self.statusView.detectAverage = [NSString stringWithFormat: @"%.2f .. %.2f", minInputLevel, maxInputLevel];
                [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
                if (1 || VL_DEBUG) NSLog(@"preRunMoreMeeded=%d\n", prerunMoreNeeded);
                if (prerunMoreNeeded == 0) {
                    outputLevel = 0.5;
                    self.statusView.detectCount = @"";
                    //self.statusView.detectAverage = @"";
                    [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
                    [self performSelectorOnMainThread: @selector(stopPreMeasuring:) withObject: self waitUntilDone: NO];
                    return;
                }
				[self.outputCompanion triggerNewOutputValue];
            }
        }
		if (!inErrorMode) {
			NSString *msg = self.device.lastErrorMessage;
			if (msg) {
				inErrorMode = YES;
				NSAlert *alert = [NSAlert alertWithMessageText:@"Hardware device error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", msg];
				[alert runModal];
			}
		}
    }
}

- (void)triggerNewOutputValue
{
	if (outputLevel > 0 && outputLevel < 1)
		outputLevel = 0;
	newOutputValueWanted = YES;
    NSLog(@"triggerNewOutputValue called");
}

- (IBAction)startPreMeasuring: (id)sender
{
	@synchronized(self) {
        [self.bPreRun setEnabled: NO];
        [self.bRun setEnabled: NO];
        if (self.statusView) {
            [self.statusView.bStop setEnabled: NO];
        }
        // Do actual prerunning
        prerunMoreNeeded = PRERUN_COUNT;
        self.preRunning = YES;
        [self.outputCompanion triggerNewOutputValue];
    }
}

- (IBAction)stopPreMeasuring: (id)sender
{
	@synchronized(self) {
		self.preRunning = NO;
        outputLevel = 0.5;
        newOutputValueWanted = NO;
		[self.bPreRun setEnabled: NO];
		[self.bRun setEnabled: YES];
		if (!self.statusView) {
			// XXXJACK Make sure statusview is active/visible
		}
		[self.statusView.bStop setEnabled: NO];
	}
}

- (IBAction)startMeasuring: (id)sender
{
    @synchronized(self) {
		[self.bPreRun setEnabled: NO];
		[self.bRun setEnabled: NO];
		if (!self.statusView) {
			// XXXJACK Make sure statusview is active/visible
		}
		[self.statusView.bStop setEnabled: YES];
        self.running = YES;
        [self.collector startCollecting: self.measurementType.name input: self.device.deviceID name: self.device.deviceName output: self.device.deviceID name: self.device.deviceName];
        [self.outputCompanion triggerNewOutputValue];
    }
}

- (void)restart
{
    @synchronized(self) {
		if (measurementType == nil) return;
        if (self.device == nil) {
            NSLog(@"HardwareRunManager: no hardware device available");
            [self.bPreRun setEnabled: NO];
            [self.bRun setEnabled: NO];
            if (self.statusView) {
                [self.statusView.bStop setEnabled: NO];
            }
            return;
        }
//
        if (measurementType.requires == nil) {
			[self.bBase setEnabled:NO];
			[self.bPreRun setEnabled: YES];
		} else {
			NSArray *calibrationNames = measurementType.requires.measurementNames;
            [self.bBase removeAllItems];
			[self.bBase addItemsWithTitles:calibrationNames];
            if ([self.bBase numberOfItems])
                [self.bBase selectItemAtIndex:0];
			[self.bBase setEnabled:YES];
			if ([self.bBase selectedItem]) {
				[self.bPreRun setEnabled: YES];
			} else {
				[self.bPreRun setEnabled: NO];
				NSAlert *alert = [NSAlert alertWithMessageText:@"No calibrations available."
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"\"%@\" measurements should be based on a \"%@\" calibration. Please calibrate first.",
                                  measurementType.name,
                                  measurementType.requires.name
                                  ];
				[alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
			}
		}
		self.preRunning = NO;
		self.running = NO;
		[self.bRun setEnabled: NO];
		if (self.statusView) {
			[self.statusView.bStop setEnabled: NO];
		}

//
        outputLevel = 0.5;
        [self.bRun setEnabled: NO];
        if (self.statusView) {
            [self.statusView.bStop setEnabled: NO];
        }
        if (!alive) {
            alive = YES;
            [self performSelectorInBackground:@selector(_periodic:) withObject:self];
        }
    }
}

- (void)stop
{
	alive = NO;
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
