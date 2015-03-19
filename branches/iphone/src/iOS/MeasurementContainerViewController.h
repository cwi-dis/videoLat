//
//  MeasurementContainerViewController.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "compat.h"

@interface MeasurementContainerViewController : UIViewController {
	NSArray *measurementNibObjects;
}

@property(strong) NSString *measurementTypeName;
@property(strong) UIView *measurementView;

@end
