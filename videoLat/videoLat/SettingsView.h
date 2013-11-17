//
//  SettingsView.h
//
//  Created by Jack Jansen on 26-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// NOTE: These tags must be set in Interface Builder too.
enum RoleTag {
    roleManual = 0,
    roleRoundTrip = 1,
    roleXmitOnly = 2,
    roleRecvOnly = 3,
    roleXmitSelf = 4,
    roleRecvSelf = 5
};

@interface SettingsView : NSView {

    // Global section
    IBOutlet NSPopUpButton *bRole;
    IBOutlet NSMatrix *bDataType;
    IBOutlet NSButtonCell *bDataTypeBlackWhite;
    IBOutlet NSButtonCell *bDataTypeQRCode;
    
    // Transmission section
    IBOutlet NSButton *bXmit;
    IBOutlet NSButton *bMirror;
 
    // Reception section
    IBOutlet NSButton *bRecv;
	IBOutlet NSPopUpButton *bCameras;

    // Coordination section
	IBOutlet NSPopUpButton *bCoordHelper;
	
    // Output section
    IBOutlet NSTextField *bFilename;
    IBOutlet NSButton *bChooseFile;
    IBOutlet NSButton *bSummarize;

    // Run section
    IBOutlet NSButton *bRunning;
    
	IBOutlet id inputHandler;     // Camera class, used to find device names

    // Tranmsmission
    bool xmit;
    bool datatypeBlackWhite;
    bool datatypeQRCode;
    bool mirrorView;

    // Reception
    bool recv;
    // Coordination
	NSString *coordHelper;

    // Output
    NSString *fileName;
    bool summarize;
    
    // Run
    bool running;

    id manager;
}

@property(readonly) bool xmit;
@property(readonly) bool datatypeQRCode;
@property(readonly) bool datatypeBlackWhite;
@property(readonly) bool mirrorView;

@property bool recv;

@property(readonly) NSString *coordHelper;

@property(readonly) NSString *fileName;
@property(readonly) bool summarize;

@property(readonly) bool running;

@property(assign) id manager;

- (IBAction)roleChanged: (id) sender;
- (IBAction)buttonChanged: (id) sender;
- (IBAction)runButtonChanged: (id) sender;
- (IBAction)cameraChanged: (id) sender;
- (IBAction)chooseFile: (id) sender;
- (void)updateButtons: (id)sender;
- (void)updateButtonsIfNeeded;
- (void)_updateCameraNames: (NSNotification*) notification;
- (void)_reselectCamera: (NSString *)name;
@end
