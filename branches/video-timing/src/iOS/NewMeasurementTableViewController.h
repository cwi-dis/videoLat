//
//  NewMeasurementTableViewController.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 15/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewMeasurementTableViewController : UITableViewController {
	NSString *selectedMeasurement;
}

- (NSArray *)measurementNames;
@end
