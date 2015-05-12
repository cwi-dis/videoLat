///
///  @file OpenDocumentTableViewController.h
///  @brief Holds definition of OpenDocumentTableViewController object (iOS only).
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <UIKit/UIKit.h>

///
/// Handle UI for opening and inspecting existing documents and calibrations.
///
@interface OpenDocumentTableViewController : UITableViewController
{
    BOOL showCalibrations;
    NSURL *selectedUrl;
}

@property (retain) NSArray *documents;

- (void) _updateDocuments;
@end
