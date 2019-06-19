//
//  MainMenuTableViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 3/04/15.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "MainMenuTableViewController.h"
#import "DocumentViewController.h"


@implementation MainMenuTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];
    if (self.dataStoreToOpen) {
		// We have gotten here through an unwind sequence, and whoever initiated
		// it wants us to open a new document
		[self performSegueWithIdentifier:@"showDocument" sender:self];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	if ([segue.identifier isEqualToString:@"showDocument"]) {
		assert(self.dataStoreToOpen);
		MeasurementDataStore *ds = self.dataStoreToOpen;
		self.dataStoreToOpen = nil;
		DocumentViewController *dvc = segue.destinationViewController;
		NSURL *newURL = [Document inventURLForDocument:ds];
		NSLog(@"URL for measurement is %@", newURL);
		assert(newURL);
		Document *newDocument = [[Document alloc] initWithFileURL: newURL];
		newDocument.dataStore = ds;
		[newDocument newDocumentComplete: self];
		dvc.document = newDocument;
	}
}

- (IBAction)unwindAndOpenDocument:(UIStoryboardSegue*)sender
{
}

@end
