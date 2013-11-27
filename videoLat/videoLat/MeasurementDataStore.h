//
//  MeasurementRun.h
//  videoLat
//
//  Created by Jack Jansen on 11/11/13.
//
//

#import <Foundation/Foundation.h>
#import "protocols.h"

@interface MeasurementDataStore : NSCoder <GraphDataProviderProtocol> {
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
@property(retain) NSString* baseMeasurementID;
@property(readonly) double baseMeasurementAverage;
@property(readonly) double baseMeasurementStddev;

- (void) addDataPoint: (NSString*) data sent: (uint64_t)sent received: (uint64_t) received;
- (void) trim;
- (NSString*) asCSVString;
- (NSNumber *)valueForIndex: (int) i;
- (void)useCalibration: (MeasurementDataStore *)calibration;
@end
