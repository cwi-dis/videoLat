//
//  MainMenuTableViewController.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 3/04/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MeasurementDataStore.h"

@interface MainMenuTableViewController : UITableViewController

@property(nonatomic,retain) IBOutlet MeasurementDataStore *dataStoreToOpen;

- (IBAction)unwindAndOpenDocument:(UIStoryboardSegue*)sender;

@end
