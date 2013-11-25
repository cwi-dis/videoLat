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
@property(retain) IBOutlet NSPopUpButton *bType;
@property(retain) IBOutlet BaseRunManager *runManager;
@property(retain) IBOutlet NSView *selectionView;
@property(retain) IBOutlet NSView *outputView;
@property(retain) IBOutlet RunStatusView *statusView;
@property(retain) IBOutlet RunCollector *collector;
@property(retain) IBOutlet Document *document;
@property(retain) IBOutlet NSView *selectionContainerView;
@property(retain) IBOutlet NSView *outputContainerView;

- (IBAction)typeChanged: (id)sender;
- (IBAction)stopMeasuring: (id)sender;

@end
