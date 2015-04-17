///
///  @file MeasurementDataStore.h
///  @brief Defines the MeasurementDataStore object.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "protocols.h"
#import "DeviceDescription.h"

///
/// Storage for all measured delays of a measurement run, plus
/// all the metadata pertaining to that run (type, input and output device used, etc).
///


@interface MeasurementDataStore : NSCoder <GraphDataProviderProtocol> {
    double sum;         //!< Internal: sum of all values
    double sumSquares;  //!< Internal: sum of the squares of all values
    double min;         //!< minimum value
    double max;         //!< maximum value
    int count;          //!< total number of values
	int missCount;      //!< number of attempts that did not result in a valid measurement
	BOOL isTrimmed;		//!< True after trim has been called at end-of-measurement
    MeasurementDataStore *calibration;  //!< calibration used, for single-machine measurements
	NSMutableArray *store;  //!< Internal: the values themselves
};

@property(strong) NSString* measurementType;        //!< Metadata variable, set by owner
@property(strong) NSString* date;                   //!< Metadata variable, set by owner
@property(strong) NSString* description;            //!< Metadata variable, set by owner
@property(strong) NSString* uuid;                   //!< Unique ID, set at init time

@property(strong) DeviceDescription *input;			//!< Input device used.
@property(strong) DeviceDescription *output;		//!< Output device used.

@property(readonly) double min;						//!< Returns minimum value measured.
@property(readonly) double max;						//!< Returns maximum value measured.
@property(readonly) double average;                 //!< Returns the average of all values
@property(readonly) double stddev;                  //!< Returns the standard deviation of all values
@property(readonly) int count;						//!< Returns number of values measured.
@property(readonly) int missCount;					//!< Returns number of failed measurements.
@property(readonly) NSString *outputBaseMeasurementID;	//!< Accessor for name of input calibration.
@property(readonly) NSString *inputBaseMeasurementID;	//!< Accessor for name of output calibration.
@property(readonly) BOOL hasSeparateCalibrations;	//!< True if we have distinct input and output calibrations
@property(readonly) MeasurementDataStore *inputCalibration;	//!< Our input calibration (or shared calibration)
@property(readonly) MeasurementDataStore *outputCalibration;	//!< Our output calibration (or shared calibration)
@property(readonly) double baseMeasurementAverage;  //!< Records average of base measurement, for convenience
@property(readonly) double baseMeasurementStddev;  //!< Records stddev of base measurement, for convenience

@property(readonly) NSString *descriptiveName;	//!< Human readable name for the type of measurement run.

/// Adds a single measurement.
/// @param data the data transmitted and received
/// @param sent the clock time at which the data was sent
/// @param received the clock time at which the data was received
/// This method adds a single delay value to the store, and updates min/max/average/stddev.
/// If the baseMeasurementAverage is non-zero it is subtracted from the delay value before processing.
- (void) addDataPoint: (NSString*) data sent: (uint64_t)sent received: (uint64_t) received;

/// Signals that  ameasurement has failed, the data was not detected in time.
/// @param data the data that was transmitted but not received
/// @param sent the clock time at which the data was sent
/// Currently this call only updates the missCount variable.
- (void) addMissingDataPoint: (NSString*) data sent: (uint64_t)sent;

/// Removes lower and upper 5% measurements and recomputes min/max/average/stddev.
/// This is a statistically valid technique (I have been told) to diminish the
/// effect of anomalous measurements on average and standard deviation.
/// Calling this more than once has no effect.
- (void) trim;

/// Return the data values (not the metadata) as a CSV string, for export.
- (NSString*) asCSVString;

/// Return value for a given index, used by graph views.
- (NSNumber *)valueForIndex: (int) i;

/// Indicates the calibration measurement for this measurement run.
/// @param calibration the calibration measurement object.
/// This call initializes the baseMeasurementAverage and baseMeasurementStddev variables.
- (void)useCalibration: (MeasurementDataStore *)calibration;

/// Indicates the input and output calibration measurement for this measurement run.
/// @param inputCalibration the calibration measurement object.
/// This call initializes the baseMeasurementAverage and baseMeasurementStddev variables.
- (void)useInputCalibration: (MeasurementDataStore *)inputCalibration;

/// Indicates the  output calibration measurement for this measurement run.
/// @param outputCalibration the calibration measurement object.
/// This call initializes the baseMeasurementAverage and baseMeasurementStddev variables.
- (void)useOutputCalibration: (MeasurementDataStore *)outputCalibration;
@end
