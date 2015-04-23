//
//  NetworkSelectionView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>
#import "NetworkInput.h"
#import "VideoSelectionView.h"

///
/// Subclass of NSView that may at some point allow user to select networking
/// parameters
///
@interface NetworkSelectionView : VideoSelectionView<NetworkViewProtocol>

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
