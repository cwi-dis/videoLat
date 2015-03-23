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
	NSArray *measurementNibObjects;
}
@property(strong) IBOutlet UIView<SelectionView> *selectionView;
@property(strong) NSString *measurementTypeName;

@end
