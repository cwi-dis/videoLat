///
///  @file InputSelectionView.h
///  @brief Holds definition of InputSelectionView object (iOS only).
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <UIKit/UIKit.h>
#import "protocols.h"

///
/// View that allows user to select input device and optionally base measurement.
///
@interface InputSelectionView : UIView<InputSelectionView,UIPickerViewDataSource, UIPickerViewDelegate> {
    NSArray *_baseNames;
}

@property(weak) IBOutlet UIPickerView *bBase;			//!< UI element: available calibration runs
@property(weak) IBOutlet UILabel *bBaseLabel;			//!< UI element: label for the calibration picker
@property(weak) IBOutlet UILabel *bInputDeviceName;		//!< UI element: name of selected input device

@end
