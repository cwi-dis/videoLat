//
//  VideoInputSelectionViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 23/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "InputSelectionViewController.h"
#import "MeasurementContainerViewController.h"

@implementation InputSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	if (!self.measurementTypeName) {
		showWarningAlert(@"No measurementType when view became active...");
		return;
	}
	NSString *runClassNib = [BaseRunManager selectionNibForMeasurementType:self.measurementTypeName];
	assert(runClassNib);
	measurementNibObjects = [[NSBundle mainBundle] loadNibNamed: runClassNib owner: self options:nil];
	if (!measurementNibObjects) {
		showWarningAlert(@"Could not load NIB file?");
		return;
	}

	// Setup base-measurement selector, if applicable, otherwsie
    assert(self.selectionView);
	MeasurementType *myType = [MeasurementType forType:self.measurementTypeName];
	BOOL isCalibration = (myType.requires == nil);
	if (isCalibration) {
		[self.selectionView disableBases];
	} else {
		NSArray *calibrationNames = myType.requires.measurementNames;
		[self.selectionView setBases: calibrationNames];
	}
	self.selectionView.frame = self.view.bounds;
	[self.view addSubview: self.selectionView];
	[self.view setNeedsLayout];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
	if (self.capturer) [self.capturer pauseCapturing:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation
- (IBAction)selectionDone:(id)sender
{
	inputDeviceName = self.selectionView.deviceName;
	baseMeasurementName = self.selectionView.baseName;
	[self performSegueWithIdentifier:@"runMeasurement" sender:self];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	assert([segue.identifier isEqualToString:@"runMeasurement"]);
	MeasurementContainerViewController *mcv = segue.destinationViewController;
	mcv.measurementTypeName = self.measurementTypeName;
	mcv.baseMeasurementName = baseMeasurementName;
	mcv.inputDeviceName = inputDeviceName;
	if (self.capturer) [self.capturer pauseCapturing:YES];
}

@end
