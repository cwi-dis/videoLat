//
//  MeasurementContainerViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "MeasurementContainerViewController.h"
#import "BaseRunManager.h"

@implementation MeasurementContainerViewController

@synthesize measurementTypeName;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	if (!measurementTypeName) {
		showWarningAlert(@"No measurementType when view became active...");
		return;
	}
	NSString *runClassNib = [BaseRunManager nibForMeasurementType:measurementTypeName];
	assert(runClassNib);
	measurementNibObjects = [[NSBundle mainBundle] loadNibNamed: runClassNib owner: self options:nil];
	if (!measurementNibObjects) {
		showWarningAlert(@"Could not load NIB file?");
		return;
	}
	[self.view addSubview: self.measurementView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
