//
//  DocumentViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "DocumentViewController.h"
#import "CalibrationSharing.h"

@interface DocumentViewController ()

@end

@implementation DocumentViewController

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

- (IBAction)documentCancel: (UIStoryboardSegue *)sender
{
	NSLog(@"documentCancel");
}

- (IBAction)documentDelete: (UIStoryboardSegue *)sender
{
	NSLog(@"documentDelete");
}

- (IBAction)documentUpload:(UIStoryboardSegue *)sender
{
	NSLog(@"documentUpload");
    CalibrationSharing *uploader = [CalibrationSharing sharedUploader];
    assert(uploader);
    [uploader uploadAsynchronously:self.document.dataStore];
}

- (IBAction)documentPrint:(UIStoryboardSegue *)sender
{
	NSLog(@"documentPrint");
}

- (IBAction)documentEmail:(UIStoryboardSegue *)sender
{
	NSLog(@"documentEmail");
}

- (IBAction)documentEmailAsPDF:(UIStoryboardSegue *)sender
{
	NSLog(@"documentEmailAsPDF");
}

- (IBAction)documentEmailAsCSV:(UIStoryboardSegue *)sender
{
	NSLog(@"documentEmailAsCSV");
}


@end
