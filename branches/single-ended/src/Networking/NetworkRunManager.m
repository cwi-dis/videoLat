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
    [self.capturer startCapturing: YES];
}

- (void)stop
{
	//[NSException raise:@"NetworkRunManager" format:@"Must override stop in subclass"];
    NSLog(@"NetworkRunManager.stop. Unsure what to do...");
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

- (void) newInputStart:(uint64_t)timestamp
{
    @synchronized(self) {
         inputStartTime = timestamp;
        
        // Sanity check: times should be monotonically increasing
        if (prevInputStartTime && prevInputStartTime >= inputStartTime) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: input clock not monotonically increasing."
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"Previous value was %lld, current value is %lld.\nConsult Helpfile if this error persists.",
                              (long long)prevInputStartTime,
                              (long long)inputStartTime];
            [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
        }
    }
}


- (void)newInputDone
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newInputDone in subclass"];
}


- (void) newInputDone: (void*)buffer width: (int)w height: (int)h format: (const char*)formatStr size: (int)size
{
    @synchronized(self) {
        if (inputStartTime == 0) {
            NSLog(@"newInputDone called, but inputStartTime==0\n");
            return;
        }

		assert(self.finder);
        char *ccode = [self.finder find: buffer width: w height: h format: formatStr size:size];
        BOOL foundQRcode = (ccode != NULL);
        if (foundQRcode) {
			NSString *code = [NSString stringWithUTF8String: ccode];
            
            // Compare the code to what was expected.
            if (prevInputCode && [code isEqualToString: prevInputCode]) {
                prevInputCodeDetectionCount++;
				NSLog(@"Found %d copies since %lld of %@", prevInputCodeDetectionCount, prevInputStartTime, prevInputCode);
            } else {
                // Any code found.
                prevInputCode = code;
                prevInputCodeDetectionCount = 0;
                prevInputStartTime = inputStartTime;
                NSLog(@"Found QR-code: %s", code);
#if 0
                // Let's first report it.
                if (self.running) {
                    BOOL ok = [self.collector recordReception: self.outputCompanion.outputCode at: inputStartTime];
                    if (!ok) {
                        NSAlert *alert = [NSAlert alertWithMessageText:@"Reception before transmission."
                                                         defaultButton:@"OK"
                                                       alternateButton:nil
                                                           otherButton:nil
                                             informativeTextWithFormat:@"Code %@ was transmitted at %lld, but received at %lld.\nConsult Helpfile if this error persists.",
                                          self.outputCompanion.outputCode,
                                          (long long)prerunOutputStartTime,
                                          (long long)inputStartTime];
                        [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
                    }
                } else if (self.preRunning) {
                    [self _prerunRecordReception: self.outputCompanion.outputCode];
                }
                // Now do a sanity check that it is greater than the previous detected code
                if (prevInputCode && [prevInputCode length] >= [self.outputCompanion.outputCode length] && [prevInputCode compare:self.outputCompanion.outputCode] >= 0) {
                    NSAlert *alert = [NSAlert alertWithMessageText:@"Warning: input QR-code not monotonically increasing."
                                                     defaultButton:@"OK"
                                                   alternateButton:nil
                                                       otherButton:nil
                                         informativeTextWithFormat:@"Previous value was %@, current value is %@.\nConsult Helpfile if this error persists.",
                                      prevInputCode, self.outputCompanion.outputCode];
                    [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
                }
                // Now let's remember it so we don't generate "bad code" messages
                // if we detect it a second time.
#endif
            }
        }
        inputStartTime = 0;
#if 0
        if (self.running) {
            self.statusView.detectCount = [NSString stringWithFormat: @"%d", self.collector.count];
            self.statusView.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.collector.average / 1000.0, self.collector.stddev / 1000.0];
            [self.statusView performSelectorOnMainThread:@selector(update:) withObject:self waitUntilDone:NO];
        }
#endif
    }
}
- (void)newInputDone: (void*)buffer
                size: (int)size
            channels: (int)channels
                  at: (uint64_t)timestamp
{
	[NSException raise:@"NetworkRunManager" format:@"Must override newInputDone in subclass"];
}
@end
