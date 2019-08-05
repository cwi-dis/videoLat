//
//  MeasurementTypeView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "RunManagerView.h"
#import "BaseRunManager.h"
#import "MeasurementType.h"
#import "AppDelegate.h"

@implementation RunManagerView
@synthesize runManager;

- (void) dealloc
{
    [self terminate];
}

- (void) terminate
{
    if (self.runManager) {
        [(BaseRunManager *)self.runManager stop];
        [(BaseRunManager *)self.runManager terminate];
    }
}
    
- (void)awakeFromNib
{
    [super awakeFromNib];
    assert(self.runManager);
    assert(self.selectionView);
    assert(self.outputView);
    assert(self.statusView);
}

@end
