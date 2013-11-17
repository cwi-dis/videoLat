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
    return [fileName retain];
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
    [self _updateCameraNames: nil];
    [self updateButtons: self];
	[self roleChanged: self];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(_updateCameraNames:)
     name:AVCaptureDeviceWasConnectedNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(_updateCameraNames:)
     name:AVCaptureDeviceWasDisconnectedNotification
     object:nil];
}

- (void)_updateCameraNames: (NSNotification*) notification
{
    NSLog(@"Cameras changed\n");
    // Remember the old selection (if any)
    NSString *oldCam = nil;
	NSMenuItem *oldItem = [bCameras selectedItem];
    if (oldItem) {
        oldCam = [oldItem title];
    } else {
        // If no camera was selected we take the one from the preferences
        oldCam = [[NSUserDefaults standardUserDefaults] stringForKey:@"Camera"];
    }
    // Add all cameras
    NSArray *newList = [inputHandler deviceNames];
    [bCameras removeAllItems];
    [bCameras addItemsWithTitles: newList];
    // Re-select old selection, if possible
    [self _reselectCamera:oldCam];
    // If this is during awakeFromNib we are done
    if (notification == nil) return;
    // Tell the input handler if the device has changed
    NSMenuItem *newItem = [bCameras selectedItem];
    NSString *newCam = [newItem title];
    if (![newCam isEqualToString:oldCam])
        [inputHandler switchToDeviceWithName:newCam];
}

- (void)_reselectCamera: (NSString *)oldCam
{
    if (oldCam)
        [bCameras selectItemWithTitle:oldCam];
    // Select first item, if nothing has been selected
    NSMenuItem *newItem = [bCameras selectedItem];
    if (newItem == nil)
        [bCameras selectItemAtIndex: 0];
}

- (IBAction)cameraChanged: (id) sender
{
	NSMenuItem *item = [sender selectedItem];
	NSString *cam = [item title];
	NSLog(@"Switch to %@\n", cam);
	[inputHandler switchToDeviceWithName: cam];
}

- (IBAction)runButtonChanged: (id) sender
{
	running = ([bRunning state] == NSOnState);
	if (running) {
		[manager startMeasuring];
	} else {
		[manager stopMeasuring];
	}
}

- (IBAction)buttonChanged: (id) sender
{
    // Data type (Note: measurement-type popup change is handled by roleChange:)
    NSButtonCell *selCell = [bDataType selectedCell];
    datatypeQRCode = selCell == bDataTypeQRCode;
    datatypeBlackWhite = selCell == bDataTypeBlackWhite;
    
    // Transmission
    xmit = [bXmit state] == NSOnState;
    mirrorView = [bMirror state] == NSOnState;

    // Reception
    recv = [bRecv state] == NSOnState;


    // Coordination
	NSMenuItem *selHelper = [bCoordHelper selectedCell];
	coordHelper = [selHelper title];

    // Output
    fileName = [[bFilename stringValue] retain];
    summarize = [bSummarize state] == NSOnState;

    // Run
    [manager settingsChanged];
}

- (IBAction)roleChanged: (id) sender
{
    NSMenuItem *selItem = [bRole selectedItem];
    BOOL enabled = NO;
	BOOL needCam = NO;
	BOOL hasCam = [inputHandler available];
    if ([selItem tag] == roleXmitOnly) {
        [bXmit setState: NSOnState];
        [bRecv setState: NSOffState];
        [bDataType selectCell: bDataTypeQRCode];
        [bCoordHelper selectItemWithTitle: @"None"];
    } else if ([selItem tag] == roleRecvOnly) {
        [bXmit setState: NSOffState];
        [bRecv setState: NSOnState];
        [bDataType selectCell: nil];
        [bCoordHelper selectItemWithTitle: @"None"];
		needCam = YES;
    } else if ([selItem tag] == roleRoundTrip) {
        [bXmit setState: NSOnState];
        [bRecv setState: NSOnState];
        [bDataType selectCell: bDataTypeQRCode];
        [bCoordHelper selectItemWithTitle: @"None"];
		needCam = YES;
    } else if ([selItem tag] == roleXmitSelf) {
        [bXmit setState: NSOnState];
        [bRecv setState: NSOffState];
        [bDataType selectCell: bDataTypeBlackWhite];
        [bCoordHelper selectItemWithTitle: @"sw_labjack"];
    } else if ([selItem tag] == roleRecvSelf) {
        [bXmit setState: NSOffState];
        [bRecv setState: NSOnState];
        [bDataType selectCell: bDataTypeBlackWhite];
        [bCoordHelper selectItemWithTitle: @"sw_labjack"];
		needCam = YES;
    } else {
        // Leave buttons as-is
        enabled = YES;
    }
	if (!hasCam) {
		[bRecv setState: NSOffState];
	}

    [bXmit setEnabled: enabled];
    [bRecv setEnabled: (enabled && hasCam)];
    [bDataType setEnabled: enabled];

    [self buttonChanged: self];
	if (needCam && !hasCam && sender != self) {
		NSRunAlertPanel(@"Error", @"This mode requires a camera", nil, nil, nil);
	}
}

- (void)chooseFile: (id) sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setExtensionHidden: NO];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"csv"]];
	[ savePanel setAllowsOtherFileTypes:YES];
	[savePanel setNameFieldStringValue: @"measurements"];
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

    // Coordination
    [bCoordHelper selectItemWithTitle: coordHelper];

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
