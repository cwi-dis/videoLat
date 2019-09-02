///
///  @file NetworkRunManager.h
///  @brief Defines NetworkRunManager object.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "VideoRunManager.h"
//#import "NetworkSelectionView.h"
#import "NetworkOutputView.h"

///
/// Subclass of BaseRunManager that handles transmitting and receiving measurement
/// data over the network as a helper device. This manager can handle either a camera
/// or a screen, but not both. It does not have a collector but sends capture times
/// or transmission times back to the remote master device.
///
@interface NetworkRunManager : VideoRunManager {
    NSString *codeRequested;    //<! QR-code requested to be shown by remote side
}

//@property(weak) IBOutlet NetworkSelectionView *selectionView;   //!< UI element: all available cameras
//@property(weak) IBOutlet NetworkOutputView *outputView;         //!< Assigned in NIB: visual feedback view of output for the user

+ (void)initialize;	//!< Class initializer.
- (void)codeRequestedByMaster: (NSString *)code;

/// Report input device name and other parameters to remote side.
- (BOOL)reportInputDeviceToRemote;

/// Report output device name and other parameters to remote side.
- (BOOL)reportOutputDeviceToRemote;

@end
