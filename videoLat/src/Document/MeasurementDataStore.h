//
//  MeasurementRun.h
//  videoLat
//
//  Created by Jack Jansen on 11/11/13.
//
//

#import <Foundation/Foundation.h>
#import "protocols.h"

///
/// Storage for all measured delays of a measurement run, plus
/// all the metadata pertaining to that run (type, input and output device used, etc).
///

@interface MeasurementDataStore : NSCoder <GraphDataProviderProtocol> {
    double sum;
    double sumSquares;
    double min;
    double max;
    int count;
	int missCount;

	NSMutableArray *store;
};

@property(strong) NSString* measurementType;
@property(strong) NSString* machineID;
@property(strong) NSString* machine;
@property(strong) NSString* inputDeviceID;
@property(strong) NSString* inputDevice;
@property(strong) NSString* outputDeviceID;
@property(strong) NSString* outputDevice;
@property(readonly) double min;
@property(readonly) double max;
@property(readonly) double average;
@property(readonly) double stddev;
@property(readonly) int count;
@property(readonly) int missCount;
@property(strong) NSString* baseMeasurementID;
@property(readonly) double baseMeasurementAverage;
@property(readonly) double baseMeasurementStddev;

- (void) addDataPoint: (NSString*) data sent: (uint64_t)sent received: (uint64_t) received;
- (void) addMissingDataPoint: (NSString*) data sent: (uint64_t)sent;
- (void) trim;
- (NSString*) asCSVString;
- (NSNumber *)valueForIndex: (int) i;
- (void)useCalibration: (MeasurementDataStore *)calibration;
@end
