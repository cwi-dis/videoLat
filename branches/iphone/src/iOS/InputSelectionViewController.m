//
//  VideoInputSelectionViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 23/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "InputSelectionViewController.h"
#import "MeasurementContainerViewController.h"

@interface InputSelectionViewController ()

@end

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

    assert(self.selectionView);

	self.selectionView.frame = self.view.bounds;
	[self.view addSubview: self.selectionView];
	[self.view setNeedsLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	MeasurementContainerViewController *mcv = segue.destinationViewController;
	mcv.measurementTypeName = self.measurementTypeName;
	NSLog(@"InputSelectionViewController: should communicate input device and base measurement");
}

@end
