//
//  SettingsView.m
//
//  Created by Jack Jansen on 26-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "SettingsView.h"

@implementation SettingsView

@synthesize xmit;
@synthesize datatypeQRCode;
@synthesize datatypeBlackWhite;
@synthesize mirrorView;

@synthesize recv;

@synthesize coordHelper;

@synthesize running;
@synthesize summarize;

@synthesize manager;

- (NSString *)fileName {
    [bChooseFile setEnabled: NO];
    return fileName;
}

- (void)awakeFromNib
{
	xmit = true;
    datatypeQRCode = true;
    datatypeBlackWhite = false;
    mirrorView = false;

    recv = true;

	coordHelper = [NSString stringWithUTF8String: "None"];

    running = false;
	summarize = true;
	
    fileName = [NSString stringWithUTF8String: "/tmp/measurements.csv"];
    [self updateButtons: self];
	[self roleChanged: self];
}



@end
