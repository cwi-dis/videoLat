//
//  MeasurementRun.h
//  videoLat
//
//  Created by Jack Jansen on 11/11/13.
//
//

#import <Foundation/Foundation.h>

@interface MeasurementRun : NSObject {
    double sum;
    double sumSquares;
    double min;
    double max;
    int count;

	NSMutableArray *store;
};

@property(readonly) double min;
@property(readonly) double max;
@property(readonly) double average;
@property(readonly) double stddev;
@property(readonly) int count;

- (void) addDataPoint: (NSString*) data sent: (uint64_t)sent received: (uint64_t) received;

@end
