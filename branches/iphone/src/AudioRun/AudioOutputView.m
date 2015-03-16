//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "AudioOutputView.h"

@implementation AudioOutputView

- (void)awakeFromNib
{
    NSBundle *bundle = [NSBundle mainBundle];
    samples = [bundle pathsForResourcesOfType:@"aif" inDirectory:@"sounds"];
    if (VL_DEBUG) NSLog(@"Sounds: %@\n", samples);
#ifdef WITH_UIKIT
    NSLog(@"Should fill picker view with samples");
#else
    [self.bSample removeAllItems];
    NSString *filename;
    for (filename in samples) {
        NSArray *comps = [filename componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"/."]];
        NSString *title = [comps objectAtIndex: [comps count] - 2];
        [self.bSample addItemWithTitle:title];
    }
#endif
	[self sampleChanged: self.bSample];
}

- (void)dealloc
{
	if (player) [player stop];
	player = nil;
}

- (NSString *)deviceID
{
    return @"systemDefault";
}

- (NSString *)deviceName
{
    return @"System Default Output";
}

- (void)stop
{
	if (player) [player stop];
	player = nil;
}

- (IBAction)sampleChanged: (id) sender
{
    // Get the URL of the sample selected
#ifdef WITH_UIKIT
    int idx = [sender selectedRowInComponent: 0];
    NSString *sample = [samples objectAtIndex:idx];
#else
    NSString *sample = [sender titleOfSelectedItem];
#endif
    NSURL * url = [[NSURL alloc] initFileURLWithPath:
                   [[NSBundle mainBundle] pathForResource:sample ofType:@"aif" inDirectory: @"sounds"]];
    if (VL_DEBUG) NSLog(@"sample URL %@\n", url);
    
    // Create the player for it
    NSError *error;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (player == nil) {
        NSLog(@"AVAudioPlayer error: %@", error);
        return;
    }
    player.delegate = self;
    player.meteringEnabled = YES;

    // Initialize the processor with it
    AudioProcess *orinigalProcessor = [self.processor clone];
    signature = [orinigalProcessor processOriginal:url];
    self.processor.originalSignature = signature;
}

- (void) showNewData
{
    if (player) {
		if (player.playing) {
			NSLog(@"AudioOutputView.showNewData: already playing");
			return;
		}
        // player.volume = self.bVolume.floatValue;
        [player prepareToPlay];
        [self.manager newOutputStart]; // XXXJACK should have a newOutputStartAt: timestamp and use playAtTime
        [player play];
    } else {
        [self.manager newOutputStart];
        NSLog(@"Pretend you hear something...");
        // Report back that we have displayed it.
        [self.manager newOutputDone];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    // Report back that we have displayed it.
    [self.manager newOutputDone];
}

- (void)updateMeters
{
    if (player) {
        [player updateMeters];
        float level = [player averagePowerForChannel: 0];
#ifdef WITH_UIKIT
        [self.bOutputValue setProgress: level];
#else
        [self.bOutputValue setFloatValue:level*100];
#endif
    }
}

@end
