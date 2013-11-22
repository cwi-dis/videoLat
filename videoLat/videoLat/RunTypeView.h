//
//  MeasurementTypeView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RunTypeView : NSView
@property(retain) IBOutlet NSPopUpButton *bType;
@property(retain) IBOutlet id runManager;

- (IBAction)typeChanged: (id)sender;

@end
