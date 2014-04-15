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
}
- (IBAction)sampleChanged: (id) sender
{
    NSString *sample = [sender titleOfSelectedItem];
    NSURL * url = [[NSURL alloc] initFileURLWithPath:
                   [[NSBundle mainBundle] pathForResource:sample ofType:@"aif" inDirectory: @"sounds"]];
    NSLog(@"sample URL %@\n", url);
}

- (void) showNewData
{
}
@end
