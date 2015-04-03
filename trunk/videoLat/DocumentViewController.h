//
//  DocumentViewController.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "MeasurementDataStore.h"
#import "MeasurementDistribution.h"
#import "DocumentView.h"
#import "Document.h"

@interface DocumentViewController : UIViewController<MFMailComposeViewControllerDelegate,UIAlertViewDelegate> {
    Document *_document;
    SEL nextAction;
}
@property(nonatomic,retain) IBOutlet DocumentView *view;
@property(nonatomic,retain) IBOutlet id auxObject;
@property(strong) Document *document; //!< data for this document

- (void)viewDidAppear:(BOOL)animated;

- (IBAction)documentCancel: (UIStoryboardSegue *)sender;
- (IBAction)documentDelete: (UIStoryboardSegue *)sender;
- (IBAction)documentUpload:(UIStoryboardSegue *)sender;
- (IBAction)documentPrint:(UIStoryboardSegue *)sender;
- (IBAction)documentEmail:(UIStoryboardSegue *)sender;
- (IBAction)documentEmailAsPDF:(UIStoryboardSegue *)sender;
- (IBAction)documentEmailAsCSV:(UIStoryboardSegue *)sender;

- (void)_doDelete: (id)dummy;
- (void)_doUpload:(id)dummy;
- (void)_doPrint:(id)dummy;
- (void)_doEmail:(id)dummy;
- (void)_doEmailAsPDF:(id)dummy;
- (void)_doEmailAsCSV:(id)dummy;
@end
