//
//  MainMenuTableViewController.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 3/04/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MeasurementDataStore.h"

///
/// Controller for initial view (iOS).
/// Allows user to select type of action (doing new easurement, viewing old measurement, etc)
/// and handles opening of new measurement documents through an unwind segue.
///
/// The control structure is a bit convoluted: when the measurement is complete that
/// view controller sets our @see dataStoreToOpen in its prepareForSegue: for the unwind
/// segue. Then our @see unwindAndOpenDocument: is called, which does nothing, and finally
/// our viewDidAppear: is called, which then starts the showDocument segue.
/// Then we, in our prepareForSegue: method, communicate @see dataStoreToOpen to the new
/// new view controller.
@interface MainMenuTableViewController : UITableViewController

/// Set by view originating the unwind segue to us.
@property(nonatomic,retain) IBOutlet MeasurementDataStore *dataStoreToOpen;

/// Unwind segue action method.
- (IBAction)unwindAndOpenDocument:(UIStoryboardSegue*)sender;

@end
