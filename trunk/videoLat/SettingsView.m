//
//  SettingsView.m
//
//  Created by Jack Jansen on 26-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "SettingsView.h"
#import "iSight.h"

@implementation SettingsView

@synthesize xmit;
@synthesize xmitQRcode;
@synthesize xmitBlackWhite;
@synthesize mirrorView;

@synthesize recv;
@synthesize detectString;
@synthesize bwString;
@synthesize blackWhiteRect;
@synthesize foundQRcode;

@synthesize waitForDetection;
@synthesize runPython;

@synthesize running;
@synthesize summarize;

@synthesize manager;

- (NSString *)fileName {
    [bChooseFile setEnabled: NO];
    return [fileName retain];
}

- (void)awakeFromNib
{
	xmit = true;
    xmitQRcode = true;
    xmitBlackWhite = false;
    mirrorView = false;

    recv = true;

    waitForDetection = true;
	runPython = false;

    running = false;
	summarize = true;
	
    blackWhiteRect = NSMakeRect(0, 0, -1, -1);
    detectString = [NSString stringWithUTF8String: "none"];
    bwString = [NSString stringWithUTF8String: "none"];
    fileName = [NSString stringWithUTF8String: "/tmp/measurements.csv"];
	[bCameras addItemsWithTitles: [inputHandler deviceNames]];
    [self updateButtons: self];
}

- (IBAction)cameraChanged: (id) sender
{
	NSMenuItem *item = [sender selectedItem];
	NSString *cam = [item title];
	NSLog(@"Switch to %@\n", cam);
	[inputHandler switchToDeviceWithName: cam];
}

- (IBAction)buttonChanged: (id) sender
{
    // Transmission
    xmit = [bXmit state] == NSOnState;
    NSButtonCell *selCell = [bXmitRadio selectedCell];
    xmitQRcode = selCell == bXmitQRcode;
    xmitBlackWhite = selCell == bXmitBlackWhite;
    mirrorView = [bMirror state] == NSOnState;

    // Reception
    recv = [bRecv state] == NSOnState;


    // Coordination
    waitForDetection = [bWait state] == NSOnState;
	runPython = [bRunPython state] == NSOnState;
    
    // Output
    fileName = [[bFilename stringValue] retain];
    summarize = [bSummarize state] == NSOnState;

    // Run
    running = [bRunning state] == NSOnState;
    [manager settingsChanged];
}

- (IBAction)roleChanged: (id) sender
{
    NSButtonCell *selCell = [bRole selectedCell];
    BOOL enabled = NO;
    if (selCell == bRoleSend) {
        [bXmit setState: NSOnState];
        [bRecv setState: NSOffState];
        [bXmitRadio selectCell: bXmitQRcode];
        [bWait setState: NSOffState];
        [bRunPython setState: NSOffState];
    } else if (selCell == bRoleRecv) {
        [bXmit setState: NSOffState];
        [bRecv setState: NSOnState];
        [bXmitRadio selectCell: nil];
        [bWait setState: NSOffState];
        [bRunPython setState: NSOffState];
    } else if (selCell == bRoleBoth) {
        [bXmit setState: NSOnState];
        [bRecv setState: NSOnState];
        [bXmitRadio selectCell: bXmitQRcode];
        [bWait setState: NSOnState];
        [bRunPython setState: NSOffState];
    } else {
        // Leave buttons as-is
        enabled = YES;
    }
    [bXmit setEnabled: enabled];
    [bRecv setEnabled: enabled];
    [bXmitRadio setEnabled: enabled];
    [bWait setEnabled: enabled];
    [bRunPython setEnabled: enabled];
    
    [self buttonChanged: self];
}

- (void)chooseFile: (id) sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
        NSURL *selUrl = [savePanel URL];
        assert([selUrl isFileURL]);
        fileName = [selUrl path];
        [self updateButtons: self];
    }
}

- (void)updateButtons: (id)sender
{
    // Transmission
    [bXmit setState: xmit?NSOnState:NSOffState];
	[bMirror setState: mirrorView?NSOnState:NSOffState];

    // Reception
    [bRecv setState: recv?NSOnState:NSOffState];
    [bDetected setStringValue: detectString];
    if (foundQRcode) {
        [bDetected setTextColor:[NSColor blackColor]];
    } else {
        [bDetected setTextColor:[NSColor redColor]];
    }
    if (NSIsEmptyRect(blackWhiteRect)) {
        [bLocation setStringValue: @"No QR code found yet"];
    } else {
        NSString * loc = [NSString stringWithFormat: @"pos %d,%d size %d,%d", 
            (int)blackWhiteRect.origin.x,
            (int)blackWhiteRect.origin.y,
            (int)blackWhiteRect.size.width,
            (int)blackWhiteRect.size.height];
        [bLocation setStringValue: loc];
    }
    [bBWstatus setStringValue: bwString];

    // Coordination
    [bWait setState: waitForDetection?NSOnState:NSOffState];
	[bRunPython setState: runPython?NSOnState:NSOffState];

    // Output
    [bFilename setStringValue: fileName];
    [bSummarize setState: summarize?NSOnState:NSOffState];

    // Run
    [bRunning setState: running?NSOnState:NSOffState];
    
}

- (void)updateButtonsIfNeeded
{
    if( [[self window] isVisible])
        [self performSelectorOnMainThread:@selector(updateButtons:) withObject:self waitUntilDone:NO];
}


@end
