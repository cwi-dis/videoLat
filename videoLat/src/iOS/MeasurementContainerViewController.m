//
//  MeasurementContainerViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "MeasurementContainerViewController.h"
#import "BaseRunManager.h"
#import "Document.h"
#import "DocumentViewController.h"
#import "MainMenuTableViewController.h"

@implementation MeasurementContainerViewController

@synthesize measurementTypeName;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	if (!measurementTypeName) {
		showWarningAlert(@"No measurementType when view became active...");
		return;
	}
    Class runClass = [BaseRunManager classForMeasurementType: measurementTypeName];
	NSString *runClassNib = [BaseRunManager nibForMeasurementType:measurementTypeName];
	assert(runClassNib);
	measurementNibObjects = [[NSBundle mainBundle] loadNibNamed: runClassNib owner: self options:nil];
	if (!measurementNibObjects) {
		showWarningAlert(@"Could not load NIB file?");
		return;
	}

    assert(self.runManager);
    assert([self.runManager class] == runClass);
    [self.runManager runForType: measurementTypeName withBase:self.baseMeasurementName];
	if (self.inputDeviceName) {
		assert(self.runManager.capturer);
		[self.runManager.capturer switchToDeviceWithName: self.inputDeviceName];
	}

	self.measurementView.frame = self.view.bounds;
	[self.view addSubview: self.measurementView];
	[self.view setNeedsLayout];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.runManager) {
        [self.runManager stop];
        [self.runManager terminate];
    }
    self.runManager = nil;
}

- (BOOL)shouldAutorotate
{
    BOOL hasVideoPreviewView = YES;
    if (!hasVideoPreviewView)
        return YES;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown) {
        return YES;
    }
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    BOOL hasVideoPreviewView = YES;
    if (!hasVideoPreviewView)
        return UIInterfaceOrientationMaskAll;
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationPortraitUpsideDown;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openUntitledDocumentWithMeasurement: (MeasurementDataStore *)dataStore
{
	NSLog(@"Finished measurement: %@", dataStore);
    if (self.runManager.capturer) [self.runManager.capturer pauseCapturing:YES];
	if (dataStore) {
		finishedDataStore = dataStore;
		[self performSegueWithIdentifier:@"unwindAndShowDocument" sender:self];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	if ([segue.identifier isEqualToString:@"unwindAndShowDocument"]) {
		assert(finishedDataStore);
		assert([segue.identifier isEqualToString:@"unwindAndShowDocument"]);
		MainMenuTableViewController *mmvc = segue.destinationViewController;
		mmvc.dataStoreToOpen = finishedDataStore;
		finishedDataStore = nil;

	}
}
@end
