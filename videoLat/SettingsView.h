//
//  SettingsView.h
//
//  Created by Jack Jansen on 26-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SettingsView : NSView {

    // Global section
    IBOutlet NSMatrix *bRole;
    IBOutlet NSButtonCell *bRoleSend;
    IBOutlet NSButtonCell *bRoleRecv;
    IBOutlet NSButtonCell *bRoleBoth;
    IBOutlet NSButtonCell *bRoleManual;

    // Transmission section
    IBOutlet NSButton *bXmit;
    IBOutlet NSMatrix *bXmitRadio;
    IBOutlet NSButtonCell *bXmitBlackWhite;
    IBOutlet NSButtonCell *bXmitQRcode;
    IBOutlet NSButton *bMirror;
 
    // Reception section
    IBOutlet NSButton *bRecv;
	IBOutlet NSPopUpButton *bCameras;
    IBOutlet NSTextField *bDetected;
    IBOutlet NSTextField *bLocation;
    IBOutlet NSTextField *bBWstatus;

    // Coordination section
    IBOutlet NSButton *bWait;
	IBOutlet NSButton *bRunPython;
	
    // Output section
    IBOutlet NSTextField *bFilename;
    IBOutlet NSButton *bChooseFile;
    IBOutlet NSButton *bSummarize;

    // Run section
    IBOutlet NSButton *bRunning;
    
	IBOutlet id inputHandler;     // Camera class, used to find device names
  @public
    // Tranmsmission
    bool xmit;
    bool xmitBlackWhite;
    bool xmitQRcode;
    bool mirrorView;

    // Reception
    bool recv;
    NSRect blackWhiteRect;
    NSString *detectString;
    NSString *bwString;
    bool foundQRcode;

    // Coordination
    bool waitForDetection;
	bool runPython;

    // Output
    NSString *fileName;
    bool summarize;
    
    // Run
    bool running;

    id manager;
}

@property(readonly) bool xmit;
@property(readonly) bool xmitQRcode;
@property(readonly) bool xmitBlackWhite;
@property(readonly) bool mirrorView;

@property bool recv;
@property(retain) NSString *detectString;
@property(retain) NSString *bwString;
@property(assign) NSRect blackWhiteRect;
@property bool foundQRcode;

@property(readonly) bool waitForDetection;
@property(readonly) bool runPython;

@property(readonly) NSString *fileName;
@property(readonly) bool summarize;

@property(readonly) bool running;

@property(assign) id manager;

- (IBAction)roleChanged: (id) sender;
- (IBAction)buttonChanged: (id) sender;
- (IBAction)cameraChanged: (id) sender;
- (IBAction)chooseFile: (id) sender;
- (void)updateButtons: (id)sender;
- (void)updateButtonsIfNeeded;

@end
