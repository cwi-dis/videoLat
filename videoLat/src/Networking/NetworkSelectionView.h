///
///  @file NetworkSelectionView.h
///  @brief Holds definition of NetworkSelectionView object.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "NetworkInput.h"
#import "VideoSelectionView.h"

///
/// Subclass of NSView that may at some point allow user to select networking
/// parameters
///
#if 0
@interface NetworkSelectionView : VideoSelectionView<NetworkViewProtocol>
#else
@interface NetworkSelectionView
#ifdef WITH_UIKIT
: InputSelectionView<NetworkViewProtocol>
#else
: NSView<SelectionView, NetworkViewProtocol>
#endif
#endif

#ifdef WITH_UIKIT
@property(weak) IBOutlet UILabel *bOurPort;     //!< UI element: shows server port
@property(weak) IBOutlet UILabel *bOurStatus;   //!< UI element: shows connection status
@property(weak) IBOutlet UILabel *bRTT;         //!< UI element: shows round-trip-time
#else
@property(weak) IBOutlet NSTextField *bOurPort;     //!< UI element: shows server port
@property(weak) IBOutlet NSTextField *bOurStatus;   //!< UI element: shows connection status
@property(weak) IBOutlet NSTextField *bRTT;         //!< UI element: shows round-trip-time
#endif

- (void) reportClient: (NSString *)ip port: (int)port isUs: (BOOL) us;
- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us;

@end
