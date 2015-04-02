//
//  DocumentViewController.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MeasurementDataStore.h"
#import "MeasurementDistribution.h"
#import "DocumentView.h"
#import "Document.h"

@interface DocumentViewController : UIViewController {
    Document *_document;
}
@property(nonatomic,retain) IBOutlet DocumentView *view;
@property(nonatomic,retain) IBOutlet id auxObject;
@property(strong) Document *document; //!< data for this document

- (IBAction)documentDelete: (UIStoryboardSegue *)sender;
- (IBAction)documentUpload:(UIStoryboardSegue *)sender;
- (IBAction)documentPrint:(UIStoryboardSegue *)sender;
- (IBAction)documentEmail:(UIStoryboardSegue *)sender;
- (IBAction)documentEmailAsPDF:(UIStoryboardSegue *)sender;
- (IBAction)documentEmailAsCSV:(UIStoryboardSegue *)sender;
@end
