///
///  @file MainMenuTableViewController.h
///  @brief Holds definition of MainMenuTableViewController object (iOS only).
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <UIKit/UIKit.h>
#import "MeasurementDataStore.h"

///
/// Controller for initial view (iOS).
/// Allows user to select type of action (doing new easurement, viewing old measurement, etc)
/// and handles opening of new measurement documents through an unwind segue.
///
/// The control structure is a bit convoluted: when the measurement is complete that
/// view controller sets our dataStoreToOpen in its prepareForSegue: for the unwind
/// segue. Then our unwindAndOpenDocument: is called, which does nothing, and finally
/// our viewDidAppear: is called, which then starts the showDocument segue.
/// Then we, in our prepareForSegue: method, communicate dataStoreToOpen to the new
/// new view controller.
@interface MainMenuTableViewController : UITableViewController

/// Set by view originating the unwind segue to us.
@property(nonatomic,retain) IBOutlet MeasurementDataStore *dataStoreToOpen;

/// Unwind segue action method.
- (IBAction)unwindAndOpenDocument:(UIStoryboardSegue*)sender;

@end
