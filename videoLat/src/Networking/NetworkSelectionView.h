///
///  @file NetworkSelectionView.h
///  @brief Holds definition of NetworkSelectionView object.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#if 0
#import "NetworkInput.h"
#endif
#import "VideoSelectionView.h"

///
/// Subclass of NSView that may at some point allow user to select networking
/// parameters
///
@interface NetworkSelectionView
#ifdef WITH_UIKIT
: InputSelectionView<NetworkViewProtocol>
#else
: NSView<InputSelectionView, NetworkViewProtocol>
#endif
#ifdef WITH_APPKIT
// These are not picked up from the InputSelectionProtocol in the XIB builder. Don't know why...
@property(weak) IBOutlet NSPopUpButton *bBase;        //!< UI element: popup showing possible base measurements
@property(weak) IBOutlet NSPopUpButton *bInputDevices;   //!< UI element: all available hardware
#endif

#ifdef WITH_UIKIT
@property(weak) IBOutlet UILabel *bOurPort;     //!< UI element: shows server port
@property(weak) IBOutlet UILabel *bNetworkStatus;   //!< UI element: shows connection status
@property(weak) IBOutlet UILabel *bRTT;         //!< UI element: shows round-trip-time
#else
@property(weak) IBOutlet NSTextField *bOurPort;     //!< UI element: shows server port
@property(weak) IBOutlet NSTextField *bNetworkStatus;   //!< UI element: shows connection status
@property(weak) IBOutlet NSTextField *bRTT;         //!< UI element: shows round-trip-time
#endif

- (void) reportClient: (NSString *)ip port: (int)port isUs: (BOOL) us;
- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us;

@end
