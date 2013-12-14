//
//  MeasurementDistribution.h
//  videoLat
//
//  Created by Jack Jansen on 27/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MeasurementDataStore.h"

@interface MeasurementDistribution : NSObject <GraphDataProviderProtocol> {
    IBOutlet id <GraphDataProviderProtocol> source;
    NSMutableArray *store;
    int binCount;
    double binSize;
}
@property(readonly) double average;
@property(readonly) double stddev;
@property(readonly) double max;
@property(readonly) double maxXaxis;

- (MeasurementDistribution *)initWithSource: (MeasurementDataStore *)source;
- (void)awakeFromNib;
- (void)setSource: (id) _source;
- (void)_recompute;
- (NSNumber *)valueForIndex: (int) i;
- (NSString *) asCSVString;
@end
