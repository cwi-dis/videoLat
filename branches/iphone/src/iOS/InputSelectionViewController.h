//
//  VideoInputSelectionViewController.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 23/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "protocols.h"

@interface InputSelectionViewController : UIViewController {
	NSArray *measurementNibObjects;		//!< Storage for selectionview nib toplevel objects
	NSString *inputDeviceName;		//!< Remember selectionview parameter during segue
	NSString *baseMeasurementName;		//!< Remember selectionview parameter during segue
}
@property(strong) IBOutlet UIView<SelectionView> *selectionView;	//!< Set by selectionview NIB
@property(strong) NSString *measurementTypeName;	//!< Set by our initiator

- (IBAction)selectionDone:(id)sender;
@end
