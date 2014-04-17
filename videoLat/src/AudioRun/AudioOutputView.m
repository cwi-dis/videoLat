//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "AudioOutputView.h"

@implementation AudioOutputView

- (void)awakeFromNib
{
    NSBundle *bundle = [NSBundle mainBundle];
    
    samples = [bundle pathsForResourcesOfType:@"aif" inDirectory:@"sounds"];
    NSLog(@"Sounds: %@\n", samples);
    [self.bSample removeAllItems];
    NSString *filename;
    for (filename in samples) {
        NSArray *comps = [filename componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"/."]];
        NSString *title = [comps objectAtIndex: [comps count] - 2];
        [self.bSample addItemWithTitle:title];
    }
	[self sampleChanged: self.bSample];
}

- (IBAction)sampleChanged: (id) sender
{
    NSString *sample = [sender titleOfSelectedItem];
    NSURL * url = [[NSURL alloc] initFileURLWithPath:
                   [[NSBundle mainBundle] pathForResource:sample ofType:@"aif" inDirectory: @"sounds"]];
    NSLog(@"sample URL %@\n", url);
    NSError *error;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (player) {
        player.delegate = self;
        player.meteringEnabled = YES;
    } else {
        NSLog(@"AVAudioPlayer error: %@", error);
    }
}

- (void) showNewData
{
    if (player) {
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
        [self.bOutputValue setFloatValue:level*100];
    }
}

@end
