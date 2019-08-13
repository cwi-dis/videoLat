///
///  @file NetworkOutputView.h
///  @brief UI to see how videoLat is communicating with another instance.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "protocols.h"

///
/// Subclass of NSView that adheres to OutputDeviceProtocol and shows currently
/// selected hardware output device.
///
@interface NetworkOutputView
#ifdef WITH_UIKIT
: UIView <OutputDeviceProtocol, NetworkViewProtocol>
#else
: NSView <OutputDeviceProtocol, NetworkViewProtocol>
#endif
#ifdef WITH_UIKIT
@property(weak) IBOutlet UILabel *bPeerIPAddress;   //!< UI element: shows server IP address
@property(weak) IBOutlet UILabel *bPeerPort;        //!< UI element: shows server port
@property(weak) IBOutlet UILabel *bPeerStatus;      //!< UI element: shows connection status
@property(weak) IBOutlet UILabel *bPeerRTT;      //!< UI element: shows roundtrip time
#else
@property(weak) IBOutlet NSTextField *bPeerIPAddress;   //!< UI element: shows server IP address
@property(weak) IBOutlet NSTextField *bPeerPort;        //!< UI element: shows server port
@property(weak) IBOutlet NSTextField *bPeerStatus;      //!< UI element: shows connection status
@property(weak) IBOutlet NSTextField *bPeerRTT;      //!< UI element: shows roundtrip time
#endif
- (void) showNewData;   //!< Called when new data should be shown

- (void) reportClient: (NSString *)ip port: (int)port isUs: (BOOL) us;
- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us;


@end
