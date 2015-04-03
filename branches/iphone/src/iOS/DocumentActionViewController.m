//
//  DocumentActionViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 3/04/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "DocumentActionViewController.h"
#import "CalibrationSharing.h"

@interface DocumentActionViewController ()

@end

@implementation DocumentActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	if (self.document) {
		self.bUpload.enabled = self.bUpload.userInteractionEnabled = [CalibrationSharing isUploadable:self.document.dataStore];
		self.bPrint.enabled = self.bPrint.userInteractionEnabled = [UIPrintInteractionController isPrintingAvailable];
	}
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
