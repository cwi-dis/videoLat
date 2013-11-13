//
//  DocumentView.h
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import <Cocoa/Cocoa.h>
#import "Protocols.h"
#import "StatusView.h"
#import "GraphView.h"
#import "MeasurementRun.h"

@interface DocumentView : NSView {
    IBOutlet StatusView *status;
    IBOutlet GraphView *values;
    IBOutlet GraphView *distribution;
    IBOutlet MeasurementRun *dataStore;
    // IBOutlet DistributionData *distribution;
    NSString *baseName;
};

- (IBAction)export: (id)sender;
- (IBAction)save: (id)sender;

@end
