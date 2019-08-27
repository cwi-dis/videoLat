///
///  @file NetworkRunManager.h
///  @brief Defines NetworkRunManager object.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "BaseRunManager.h"
#import "NetworkSelectionView.h"
#import "NetworkOutputView.h"

///
/// Subclass of BaseRunManager that handles transmitting and receiving measurement
/// data over the network as a slave device. This manager can handle either a camera
/// or a screen, but not both. It does not have a collector but sends capture times
/// or transmission times back to the remote master device.
///
@interface NetworkRunManager : BaseRunManager {
}

@property(weak) IBOutlet NetworkSelectionView *selectionView;   //!< UI element: all available cameras
//@property(weak) IBOutlet NetworkOutputView *outputView;         //!< Assigned in NIB: visual feedback view of output for the user

+ (void)initialize;	//!< Class initializer.

@end
