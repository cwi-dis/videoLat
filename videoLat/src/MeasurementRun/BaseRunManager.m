//
//  BaseRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "BaseRunManager.h"
#import "MachineDescription.h"
#import "AppDelegate.h"
#import "EventLogger.h"

static NSMutableDictionary *runManagerClasses;
static NSMutableDictionary *runManagerNibs;
#ifdef WITH_UIKIT
static NSMutableDictionary *runManagerSelectionNibs;
#endif
@implementation BaseRunManager

@synthesize running;
@synthesize preRunning;
@synthesize prevOutputCode;

- (int) initialPrerunCount
{
	[NSException raise:@"BaseRunManager" format:@"Must override initialPrerunCount in subclass %@", [self class]];
	return 1;
}

- (int) initialPrerunDelay
{
	[NSException raise:@"BaseRunManager" format:@"Must override initialPrerunDelay in subclass %@", [self class]];
	return 1;
}


+ (void)initialize
{
    runManagerClasses = [[NSMutableDictionary alloc] initWithCapacity:10];
    runManagerNibs = [[NSMutableDictionary alloc] initWithCapacity:10];
#ifdef WITH_UIKIT
    runManagerSelectionNibs = [[NSMutableDictionary alloc] initWithCapacity:10];
#endif
}

+ (void)registerClass: (Class)managerClass forMeasurementType: (NSString *)name
{
    // XXXJACK assert it is a subclass of BaseRunManager
    Class oldClass = [runManagerClasses objectForKey:name];
    if (oldClass != nil && oldClass != managerClass) {
        NSLog(@"BaseRunManager: attempt to set class for %@ to %@ but it was already set to %@\n", name, managerClass, oldClass);
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

#ifdef WITH_UIKIT
+ (void)registerSelectionNib: (NSString*)nibName forMeasurementType: (NSString *)name
{
    NSString *oldNib = [runManagerSelectionNibs objectForKey:name];
    if (oldNib != nil && oldNib != nibName) {
        NSLog(@"BaseRunManager: attempt to set Nib for %@ to %@ but it was already set to %@\n", name, nibName, oldNib);
        abort();
    }
    if (VL_DEBUG) NSLog(@"BaseRunManager: Register selection nib%@ for %@\n", nibName, name);
    [runManagerSelectionNibs setObject:nibName forKey:name];
}

+ (NSString *)selectionNibForMeasurementType: (NSString *)name
{
    return [runManagerSelectionNibs objectForKey:name];
}
#endif

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
    [super awakeFromNib];
    if (handlesInput) assert(self.capturer);
    if (handlesOutput) {
        assert(self.outputView);
        assert(self.collector);
    }
    if (handlesInput) assert(self.statusView);
#ifdef WITH_APPKIT
    assert(self.selectionView);
    assert(self.measurementMaster);
#endif

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
    if (self.collector == nil && !slaveHandler) {
        errorMessage = [NSString stringWithFormat:@"Programmer error: %@ has collector==nil", self];
    }
    
    if (errorMessage) {
        showWarningAlert(errorMessage);
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

#ifdef WITH_UIKIT
- (void)runForType: (NSString *)measurementTypeName withBase: (NSString *)baseMeasurementName
{
	baseName = baseMeasurementName;
	[self selectMeasurementType:measurementTypeName];
	if (!slaveHandler)
		[self startPreMeasuring:self];
}
#endif

- (IBAction)selectionChanged: (id) sender
{
	NSLog(@"BaseRunManager: device changed");
}

- (IBAction)startPreMeasuring: (id)sender
{
	@synchronized(self) {
 		assert(!self.preRunning);
		assert(!self.running);
       assert(handlesInput);
		// First check that everything is OK with base measurement and such
		if (self.measurementType.requires != nil) {
			// First check that a base measurement has been selected.
			NSString *errorMessage;
			if (self.selectionView) baseName = [self.selectionView baseName];
			MeasurementType *baseType = self.measurementType.requires;
			MeasurementDataStore *baseStore = [baseType measurementNamed: baseName];
			if (baseType == nil) {
				errorMessage = @"No base (calibration) measurement selected.";
			} else {
				// Check that the base measurement is compatible with this measurement,
				NSString *hwName = [[MachineDescription thisMachine] machineTypeID];
				// For all runs that are not single-ended clibrations the hardware platform should match the one in the calibration run
                if (handlesOutput && !self.measurementType.outputOnlyCalibration && ![baseStore.output.machineTypeID isEqualToString:hwName]) {
                    errorMessage = [NSString stringWithFormat:@"Current machine is %@, otput base measurement done on %@", hwName, baseStore.output.machineTypeID];
                }
                if (handlesInput && !self.measurementType.inputOnlyCalibration && ![baseStore.input.machineTypeID isEqualToString:hwName]) {
                    errorMessage = [NSString stringWithFormat:@"Current machine is %@, input base measurement done on %@", hwName, baseStore.input.machineTypeID];
                }
                // For runs where we are responsible for input the input device should match
				assert(self.capturer);
                if (!self.measurementType.inputOnlyCalibration && ![baseStore.input.deviceID isEqualToString:self.capturer.deviceID]) {
                    errorMessage = [NSString stringWithFormat:@"Input %@ selected, base measurement done with %@", self.capturer.deviceName, baseStore.input.device];
                }
				if (handlesOutput) {
					assert(self.outputView);
				}
				// For runs where we are responsible for output the output device should match
                if (!self.measurementType.outputOnlyCalibration && ![baseStore.output.deviceID isEqualToString:self.outputView.deviceID]) {
					errorMessage = [NSString stringWithFormat:@"Output %@ selected, base measurement done with %@", self.outputView.deviceName, baseStore.output.device];
				}
			}
			if (errorMessage) {
				showWarningAlert(errorMessage);
			}
			[self.collector.dataStore useCalibration:baseStore];
				
		}
#ifdef WITH_APPKIT
		[self.selectionView.bPreRun setEnabled: NO];
#endif
		if (self.statusView) {
			[self.statusView.bRun setEnabled: NO];
			[self.statusView.bStop setEnabled: NO];
		}
		// Do actual prerunning
        if (!handlesOutput) {
            BOOL ok = [self.outputCompanion companionStartPreMeasuring];
            if (!ok) return;
        }
        // Do actual prerunning
        maxDelay = self.initialPrerunDelay; // Start with 1ms delay (ridiculously low)
        prerunMoreNeeded = self.initialPrerunCount;
        self.preRunning = YES;
		VL_LOG_EVENT(@"startPremeasuring", 0LL, @"");
		[self.capturer startCapturing: YES];
		[self.outputCompanion triggerNewOutputValue];
	}
}

- (IBAction)stopPreMeasuring: (id)sender
{
	@synchronized(self) {
		assert(self.preRunning);
		assert(!self.running);
		self.preRunning = NO;
		// We now have a ballpark figure for the maximum delay. Use 4 times that as the highest
		// we are willing to wait for.
		maxDelay = maxDelay * 4;
        if (!handlesOutput)
            [self.outputCompanion companionStopPreMeasuring];
		[self.capturer stopCapturing];
#ifdef WITH_APPKIT
		[self.selectionView.bPreRun setEnabled: NO];
#endif
		assert (self.statusView);
		[self.statusView.bRun setEnabled: YES];
		[self.statusView.bStop setEnabled: NO];
		VL_LOG_EVENT(@"stopPremeasuring", 0LL, @"");
	}
}

- (IBAction)startMeasuring: (id)sender
{
    @synchronized(self) {
		assert(!self.preRunning);
		assert(!self.running);
        assert(handlesInput);
		assert(self.measurementType.name);
		assert(self.capturer.deviceID);
		assert(self.capturer.deviceName);
		NSorUIView <OutputViewProtocol> *outputView;
		if (handlesOutput)
			outputView = self.outputView;
		else
			outputView = self.outputCompanion.outputView;
		assert(outputView.deviceID);
		assert(outputView.deviceName);
#ifdef WITH_APPKIT
		[self.selectionView.bPreRun setEnabled: NO];
#endif
		assert(self.statusView);
		[self.statusView.bRun setEnabled: NO];
		[self.statusView.bStop setEnabled: YES];
        self.running = YES;
		VL_LOG_EVENT(@"startMeasuring", 0LL, @"");
        if (!handlesOutput)
            [self.outputCompanion companionStartMeasuring];
        [self.capturer startCapturing: NO];
        [self.collector startCollecting: self.measurementType.name input: self.capturer.deviceID name: self.capturer.deviceName output: outputView.deviceID name: outputView.deviceName];
        [self.outputCompanion triggerNewOutputValue];
    }
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

- (BOOL) prepareInputDevice
{
	return YES;
}

- (BOOL) prepareOutputDevice
{
	return YES;
}

- (void)restart
{
	@synchronized(self) {
        if (self.measurementType == nil) {
            NSLog(@"Error: BaseRunManager.restart called without measurementType");
            return;
        }
        assert(handlesInput);
#ifdef WITH_APPKIT
		if (!self.selectionView) {
			// XXXJACK Make sure selectionView is active/visible
			assert(0);
		}
		if (self.measurementType.requires == nil) {
			[self.selectionView.bBase setEnabled: NO];
			[self.selectionView.bPreRun setEnabled: YES];
		} else {
			NSArray *calibrationNames = self.measurementType.requires.measurementNames;
            [self.selectionView.bBase removeAllItems];
			[self.selectionView.bBase addItemsWithTitles:calibrationNames];
            if ([self.selectionView.bBase numberOfItems])
                [self.selectionView.bBase selectItemAtIndex:0];
			[self.selectionView.bBase setEnabled:YES];

			if ([self.selectionView.bBase selectedItem]) {
				[self.selectionView.bPreRun setEnabled: YES];
			} else {
				[self.selectionView.bPreRun setEnabled: NO];
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText: @"No calibrations available."];
                [alert setInformativeText: [NSString stringWithFormat:@"\"%@\" measurements should be based on a \"%@\" calibration. Please calibrate first.",
                                            self.measurementType.name,
                                            self.measurementType.requires.name
                                            ]];
                [alert addButtonWithTitle: @"OK"];
				[alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
			}
		}
#endif
		self.preRunning = NO;
		self.running = NO;
		VL_LOG_EVENT(@"restart", 0LL, self.measurementType.name);
		if (self.statusView) {
			[self.statusView.bRun setEnabled: NO];
			[self.statusView.bStop setEnabled: NO];
		}
        BOOL devicesOK = ([self prepareInputDevice] && [self.outputCompanion prepareOutputDevice]);
#ifdef WITH_APPKIT
		[self.selectionView.bPreRun setEnabled: devicesOK];
#endif
	}
}

- (void) companionRestart
{
	self.preRunning = NO;
	self.running = NO;
}
- (void)stop
{
	[NSException raise:@"BaseRunManager" format:@"Must override stop in subclass %@", [self class]];
}

    
- (IBAction)stopMeasuring: (id)sender
{
	VL_LOG_EVENT(@"stop", 0LL, @"");
	assert(self.running);
	self.running = NO;
    [self stop];
    [self.collector stopCollecting];
    [self.collector trim];
    self.statusView.detectCount = [NSString stringWithFormat: @"%d (after trimming 5%%)", self.collector.count];
    self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
    [self.statusView update: self];
	if (self.completionHandler) {
        [self.completionHandler performSelectorOnMainThread:@selector(openUntitledDocumentWithMeasurement:) withObject: self.collector.dataStore waitUntilDone: NO];
	} else {
#ifdef WITH_APPKIT
		AppDelegate *d = (AppDelegate *)[[NSApplication sharedApplication] delegate];
        [d performSelectorOnMainThread:@selector(openUntitledDocumentWithMeasurement:) withObject:self.collector.dataStore waitUntilDone:NO];
		[self.statusView.window close];
#else
		assert(0);
#endif
	}
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

- (void)setFinderRect: (NSorUIRect)theRect
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

- (void) newInputDone: (NSString *)data count: (int)count at: (uint64_t) timestamp
{
    [NSException raise:@"BaseRunManager" format:@"Must override newInputDone:count:at in subclass %@", [self class]];
}


- (void) newInputDone: (CVImageBufferRef) image
{
	[NSException raise:@"BaseRunManager" format:@"Must override newInputDone: in subclass %@", [self class]];
}

- (void)newInputDone: (void*)buffer
                size: (int)size
            channels: (int)channels
                  at: (uint64_t)timestamp
				  duration: (uint64_t)duration
{
	[NSException raise:@"BaseRunManager" format:@"Must override newInputDone:buffer:size:channels:at in subclass %@", [self class]];
}

- (NSString *)genPrerunCode
{
    return nil;
}
@end
