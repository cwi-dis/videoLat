///
///  @file HardwareSelectionView.h
///  @brief UI to select Arduino/Labjack hardware device.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "protocols.h"

///
/// Subclass of NSView that allows user to select camera to use as input source
/// and possibly the calibration run to base the new measurement run on.
/// This is a separate class because it is shared among the various video-based
/// measurement runs.
///
@interface HardwareSelectionView : NSView<InputSelectionView>
#ifdef WITH_APPKIT
// These are not picked up from the InputSelectionProtocol in the XIB builder. Don't know why...
@property(weak) IBOutlet NSPopUpButton *bBase;        //!< UI element: popup showing possible base measurements
@property(weak) IBOutlet NSPopUpButton *bInputDevices;   //!< UI element: all available hardware
#endif
@end
