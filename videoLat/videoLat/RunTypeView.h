//
//  MeasurementTypeView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseRunManager.h"
#import "RunStatusView.h"
#import "RunCollector.h"

@interface RunTypeView : NSView {
	NSArray *runManagerNibObjects;	// Storage for toplevel object references from loaded nibfiles
    BOOL wasAwokenFromNib;
}
@property(weak) IBOutlet NSPopUpButton *bType;
@property(strong) IBOutlet BaseRunManager *runManager;
@property(weak) IBOutlet NSView *selectionView;
@property(weak) IBOutlet NSView *outputView;
@property(weak) IBOutlet RunStatusView *statusView;
@property(weak) IBOutlet RunCollector *collector;
@property(weak) IBOutlet Document *document;
@property(weak) IBOutlet NSView *selectionContainerView;
@property(weak) IBOutlet NSView *outputContainerView;

- (IBAction)typeChanged: (id)sender;
- (IBAction)stopMeasuring: (id)sender;

@end
