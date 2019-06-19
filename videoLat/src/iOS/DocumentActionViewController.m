//
//  DocumentActionViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 3/04/15.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "DocumentActionViewController.h"
#import "CalibrationSharing.h"

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

@end
