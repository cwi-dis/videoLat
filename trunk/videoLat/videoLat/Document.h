//
//  Document.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MeasurementRun.h"

@interface Document : NSDocument {
    NSString *baseName;
    NSArray *objectsForNewDocument;
}
@property(retain) IBOutlet MeasurementRun *dataStore;
@property(retain) IBOutlet MeasurementDistribution *dataDistribution;
@property(retain) IBOutlet id myView;

- (IBAction)newDocumentComplete: (id)sender;
- (IBAction)export: (id)sender;
- (IBAction)save: (id)sender;

@end
