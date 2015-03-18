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
#import "DocumentView.h"
#import "Document.h"

@interface DocumentViewController : UIViewController {
}
@property(nonatomic,retain) IBOutlet DocumentView *view;
@property(nonatomic,retain) IBOutlet id auxObject;
@property(strong) Document *document; //!< data for this document

@end
