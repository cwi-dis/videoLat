///
///  @file InputSelectionViewController.h
///  @brief Holds definition of InputSelectionViewController object.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <UIKit/UIKit.h>
#import "protocols.h"

///
/// Baseclass to handle UI for selecting input device (and possibly calibration) for a new measurement.
///
@interface InputSelectionViewController : UIViewController {
	NSArray *measurementNibObjects;		//!< Storage for selectionview nib toplevel objects
	NSString *inputDeviceName;		//!< Remember selectionview parameter during segue
	NSString *baseMeasurementName;		//!< Remember selectionview parameter during segue
}
@property(strong) IBOutlet UIView<InputSelectionView> *selectionView;	//!< Set by selectionview NIB
@property(weak) IBOutlet NSObject<InputDeviceProtocol> *capturer;	//!< Set by selectionview NIB
@property(strong) NSString *measurementTypeName;	//!< Set by our initiator

- (IBAction)selectionDone:(id)sender;
@end
