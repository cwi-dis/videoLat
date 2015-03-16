//
//  DocumentViewController.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MeasurementDataStore.h"
#import "MeasurementDistribution.h"

@interface DocumentViewController : UIViewController {
	MeasurementDataStore *_dataStore;
}
@property(strong) IBOutlet MeasurementDataStore *dataStore; //!< data for this document
@property(strong) IBOutlet MeasurementDistribution *dataDistribution;   //!< distribution of dataStore

@end
