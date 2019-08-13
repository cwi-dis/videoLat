///
///  @file VideoOutputView.h
///  @brief Show QR-codes or B/W images in a window.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "protocols.h"

///
/// Subclass of NSView that displays newly generated images (black/white or QRcode)
/// by asking the run manager for new data.
///
/// The object also records the output device ID, by determining on which display it is
/// being shown, and communicates this to the run manager.
///
@interface VideoOutputView
#ifdef WITH_UIKIT
 : UIView <OutputDeviceProtocol>
#else
 : NSView <OutputDeviceProtocol>
#endif
{
#ifdef xxxjacknotneeded
	NSString *deviceID;
#endif
}

@property(weak) IBOutlet id <RunOutputManagerProtocol> manager; //!< Set by NIB: our run manager

#ifdef WITH_APPKIT
/// Internal: the screen our window was on during the last redraw.
/// Used to update deviceID and deviceName when the user moves our window to a different screen.
@property(weak) NSScreen *oldScreen;
@property(weak) IBOutlet NSTextField *bOutputName;              //!< UI element: shows our device name
#endif

+ (NSArray *) allDeviceTypeIDs;

- (void) showNewData;

- (void)drawRect:(NSorUIRect)dirtyRect; //!< redraw callback
 
@end
