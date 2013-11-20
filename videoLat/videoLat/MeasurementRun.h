//
//  MeasurementRun.h
//  videoLat
//
//  Created by Jack Jansen on 11/11/13.
//
//

#import <Foundation/Foundation.h>
#import "protocols.h"

@interface MeasurementRun : NSCoder <GraphDataProviderProtocol> {
    double sum;
    double sumSquares;
    double min;
    double max;
    int count;

	NSMutableArray *store;
};

@property(retain) NSString* measurementType;
@property(retain) NSString* inputDeviceID;
@property(retain) NSString* inputDevice;
@property(retain) NSString* outputDeviceID;
@property(retain) NSString* outputDevice;
@property(readonly) double min;
@property(readonly) double max;
@property(readonly) double average;
@property(readonly) double stddev;
@property(readonly) int count;

- (void) addDataPoint: (NSString*) data sent: (uint64_t)sent received: (uint64_t) received;
- (void) trim;
- (NSString*) asCSVString;
- (NSNumber *)valueForIndex: (int) i;
@end

@interface MeasurementDistribution : NSObject <GraphDataProviderProtocol> {
    IBOutlet id <GraphDataProviderProtocol> source;
    NSMutableArray *store;
    int binCount;
    double binSize;
}

- (MeasurementDistribution *)initWithSource: (MeasurementRun *)source;
- (void)awakeFromNib;
- (void)setSource: (id) _source;
- (void)_recompute;
- (NSNumber *)valueForIndex: (int) i;
@end
