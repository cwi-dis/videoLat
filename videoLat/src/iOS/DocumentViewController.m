//
//  DocumentViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "DocumentViewController.h"
#import "DocumentActionViewController.h"
#import "CalibrationSharing.h"

@implementation DocumentViewController
@dynamic view;

- (Document *)document { return _document; }
- (void) setDocument: (Document *)document
{
    _document = document;
    if (self.view) self.view.modelObject = document;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.modelObject = _document;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Actions, and handling when to display them
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString: @"documentAction"]) {
		DocumentActionViewController *davc = [segue destinationViewController];
		davc.document = self.document;
	}
}

- (void) viewDidAppear:(BOOL)animated
{
    NSLog(@"viewDidAppear nextAction=%p", nextAction);
    [super viewDidAppear:animated];
    if (nextAction) {
        SEL _action = nextAction;
        nextAction = nil;
        [self performSelectorOnMainThread: _action withObject:nil waitUntilDone:NO];
    }
}

- (IBAction)documentCancel: (UIStoryboardSegue *)sender
{
	NSLog(@"documentCancel");
    nextAction = nil;
}

- (IBAction)documentDelete: (UIStoryboardSegue *)sender
{
	NSLog(@"documentDelete");
    nextAction = @selector(_doDelete:);
}

- (void) _doDelete:(id)dummy
{
	NSString *message = [NSString stringWithFormat:@"Are you sure you want to delete %@?", [self.document.fileURL lastPathComponent]];
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Delete Measurement"
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* cancel = [UIAlertAction
                         actionWithTitle:@"Cancel"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                         }];
    
    [alert addAction:cancel];
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"Delete"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                             NSURL *url = self.document.fileURL;
                             NSFileManager *fm = [NSFileManager defaultManager];
                             
                             NSError *error;
                             BOOL ok = [fm removeItemAtURL:url error:&error];
                             if (!ok) {
                                 showErrorAlert(error);
                                 return;
                             }
                             [self performSegueWithIdentifier:@"unwindToMainMenu" sender:self];
                         }];
    
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)documentUpload:(UIStoryboardSegue *)sender
{
	NSLog(@"documentUpload");
    nextAction = @selector(_doUpload:);
}

- (void) _doUpload: (id) dummy
{
    NSLog(@"doUpload");
   CalibrationSharing *uploader = [CalibrationSharing sharedUploader];
    assert(uploader);
    assert(self.document);
    assert(self.document.dataStore);
    [uploader uploadAsynchronously:self.document.dataStore];
}

- (IBAction)documentPrint:(UIStoryboardSegue *)sender
{
	NSLog(@"documentPrint");
    nextAction = @selector(_doPrint:);
}

- (void) _doPrint: (id) dummy
{
    NSLog(@"doPrint");
    NSData *docData = [self.view generatePDF];
	assert([UIPrintInteractionController canPrintData: docData]);

    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
        ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
            if(!completed && error){
                showErrorAlert(error);
            }
        };
    
    UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
	UIPrintInfo *printInfo = [UIPrintInfo printInfo];
	printInfo.outputType = UIPrintInfoOutputGeneral;
	printInfo.jobName = [self.document.fileURL lastPathComponent];
	printInfo.duplex = UIPrintInfoDuplexLongEdge;
	controller.printInfo = printInfo;
	controller.showsPageRange = NO;
	controller.printingItem = docData;

    [controller presentAnimated:YES completionHandler:completionHandler];
}

- (IBAction)documentEmail:(UIStoryboardSegue *)sender
{
	NSLog(@"documentEmail");
    nextAction = @selector(_doEmail:);
}

- (void) _doEmail: (id) dummy
{
    NSLog(@"doEmail");
    assert(self.document);
    NSError *error;
    NSData *docData = [self.document contentsForType:@"videolat"error:&error];
    if (error) {
        showErrorAlert(error);
        return;
    }
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    [picker setSubject:@"videoLat measurement result"];
    
    // Set up recipients
    
    // Attach the data to the email
    [picker addAttachmentData:docData mimeType:@"application/octet-stream" fileName: [self.document.fileURL lastPathComponent]];
    
    // Fill out the email body text
    
    [self presentViewController:picker animated:YES completion:NULL];

    
}

- (IBAction)documentEmailAsPDF:(UIStoryboardSegue *)sender
{
	NSLog(@"documentEmailAsPDF");
    nextAction = @selector(_doEmailAsPDF:);
}

- (void) _doEmailAsPDF: (id) dummy
{
    NSLog(@"doEmailAsPDF");
    NSData *docData = [self.view generatePDF];
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    [picker setSubject:@"PDF of videoLat measurement result"];
    
    // Set up recipients
    
    // Attach the data to the email
    NSString *baseName = [[self.document.fileURL lastPathComponent] stringByDeletingPathExtension];    // Attach the data to the email
    [picker addAttachmentData:docData mimeType:@"application/pdf" fileName: [baseName stringByAppendingPathExtension:@"pdf"]];
    
    // Fill out the email body text
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)documentEmailAsCSV:(UIStoryboardSegue *)sender
{
	NSLog(@"documentEmailAsCSV");
    nextAction = @selector(_doEmailAsCSV:);
}

- (void) _doEmailAsCSV: (id) dummy
{
    NSLog(@"doEmailAsCSV");
    assert(self.document);
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    [picker setSubject:@"videoLat measurement result as CSV files"];
    
    // Set up attachments
    NSString *baseName = [[self.document.fileURL lastPathComponent] stringByDeletingPathExtension];    // Attach the data to the email
    [picker addAttachmentData:[[self.document asCSVString] dataUsingEncoding:NSUTF8StringEncoding]
                     mimeType:@"text/csv"
                     fileName: [baseName stringByAppendingString:@"-description.csv"]];
    [picker addAttachmentData:[[self.document.dataStore asCSVString] dataUsingEncoding:NSUTF8StringEncoding]
                     mimeType:@"text/csv"
                     fileName: [baseName stringByAppendingString:@"-measurements.csv"]];
    [picker addAttachmentData:[[self.document.dataDistribution asCSVString] dataUsingEncoding:NSUTF8StringEncoding]
                     mimeType:@"text/csv"
                     fileName: [baseName stringByAppendingString:@"-distribution.csv"]];
    
    // Fill out the email body text
    
    [self presentViewController:picker animated:YES completion:NULL];
    
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (error) {
        showErrorAlert(error);
    } else {
        switch (result)
        {
            case MFMailComposeResultCancelled:
            case MFMailComposeResultSaved:
            case MFMailComposeResultSent:
                break;
            case MFMailComposeResultFailed:
                showWarningAlert(@"Mail sending failed");
                break;
            default:
                showWarningAlert(@"Result: Mail not sent");
                break;
        }
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
