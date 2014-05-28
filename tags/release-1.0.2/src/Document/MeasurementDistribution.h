//
//  MeasurementDistribution.h
//  videoLat
//
//  Created by Jack Jansen on 27/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>
#import "MeasurementDataStore.h"

@interface MeasurementDistribution : NSObject <GraphDataProviderProtocol> {
    NSMutableArray *store;
    int binCount;
    double binSize;
}
@property(readonly) double average;
@property(readonly) double stddev;
@property(readonly) double max;
@property(readonly) double maxXaxis;
@property(weak) IBOutlet id <GraphDataProviderProtocol> source;

- (MeasurementDistribution *)initWithSource: (MeasurementDataStore *)source;
- (void)awakeFromNib;
- (void)_recompute;
- (NSNumber *)valueForIndex: (int) i;
- (NSString *) asCSVString;
@end
