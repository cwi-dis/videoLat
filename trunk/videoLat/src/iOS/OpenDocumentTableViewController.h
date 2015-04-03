//
//  OpenCalibrationTableViewController.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 18/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenDocumentTableViewController : UITableViewController
{
    BOOL showCalibrations;
    NSURL *selectedUrl;
}

@property (retain) NSArray *documents;

- (void) _updateDocuments;
@end
