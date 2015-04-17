///
///  @file MeasurementDistribution.h
///  @brief Defines the MeasurementDistribution object.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "MeasurementDataStore.h"

///
/// Compute distributions for datapoints.
///
/// This object is created with a MeasurementDataSource and will compute
/// the distribution of the input values over 100 bins. It implements
/// the GraphDataProviderProtocol so it can then be used to show a distribution
/// plot of a set of measurement values.
///

@interface MeasurementDistribution : NSObject <GraphDataProviderProtocol> {
    NSMutableArray *store;  //!< Internal: storage for our distribution bins
    int binCount;           //!< Internal: number of bins in store
    double binSize;         //!< Internal: width of each bin
}
@property(readonly) double average;     //!< accessor for average of source
@property(readonly) double stddev;      //!< accessor for stddev of source
@property(readonly) double max;         //!< current maximum value (value of biggest bin)
@property(readonly) double maxXaxis;    //!< maximum of source, and therefore our rightmost data point
@property(readonly) double binSize;		//!< width of each bin
@property(weak) IBOutlet id <GraphDataProviderProtocol> source; //!< Source of our data points

/// Initializer.
/// @param source the set of datapoints this object should compute the distribution of
/// The current implementation expects the source to be static, i.e. it only recomputes the distribution initially
/// and assumes the data in the source doesn't change.
- (MeasurementDistribution *)initWithSource: (MeasurementDataStore *)source;

- (void)awakeFromNib;                   //!< Initializer
- (void)_recompute;                     //!< Internal: recompute distribution
- (NSNumber *)valueForIndex: (int) i;   //!< Used by GraphView: get one data point
- (NSString *) asCSVString;             //!< Get distribution data as CSV string
@end
