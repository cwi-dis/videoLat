//
//  MeasurementTypeView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "RunManagerView.h"
#import "BaseRunManager.h"
#import "MeasurementType.h"
#import "AppDelegate.h"

@implementation RunManagerView
@synthesize runManager;

- (void) dealloc
{
    if (self.runManager) [(BaseRunManager *)self.runManager stop];
}

- (void) terminate
{
    if (self.runManager) [(BaseRunManager *)self.runManager stop];
}
    
- (void)awakeFromNib
{
}

@end
