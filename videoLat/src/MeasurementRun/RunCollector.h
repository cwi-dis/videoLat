///
///  @file RunCollector.h
///  @brief Defines the RunCollector object.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import <stdio.h>
//XXXJACK#import "Document.h"
#import "protocols.h"
#import "MeasurementDataStore.h"

///
/// Helper object for BaseRunManager. Records transmission and reception times and populates
/// MeasurementDataStore.
/// During compile time the decision can be made to either have RunCollector use an internal clock,
/// or use a clock defined externally and assigned in the NIB. The latter is better, and
/// will normally use a clock provided by the input driver.
///
@interface RunCollector : NSObject {
    NSString* lastTransmission;         //!< Internal: records most recently transmitted data
    uint64_t lastTransmissionTime;      //!< Internal: records timestamp of most recent transmission
    BOOL lastTransmissionReceived;      //!< Internal: true when lastTramsnission has already been received
	MeasurementDataStore *dataStore;
}
@property(readonly) double average;             //!< accessor for dataStore average
@property(readonly) double stddev;              //!< accessor for dataStore stddev
@property(readonly) int count;                  //!< accessor for dataStore count
@property(readonly) MeasurementDataStore *dataStore;    //!< Where this RunCollector should store the measurements.


///
/// Fill RunCollector input parameters.
/// @param inputId the input device in somewhat-human-readable form
/// @param inputName the input device in human readable (but possibly ambiguous) form
///
- (void) setInput: (NSString*)inputId name: (NSString*)inputName;
///
/// Fill RunCollector output parameters.
/// @param outputId the output device in somewhat-human-readable form
/// @param outputName the output device in human readable (but possibly ambiguous) form
///
- (void) setOutput:(NSString*)outputId name: (NSString*)outputName;
///
/// Signals that this RunCollector should start filling its dataStore.
/// The input and output calibrations should have been set previously and are used to fill the devices.
/// @param scenario the measurement type in somewhat-human-readable form
///
- (void) startCollecting: (NSString*)scenario;
- (void) stopCollecting;    //!< Stop filling the dataStore
- (void) trim;              //!< Tell the dataStore to trim its data

///
/// Called when a transmission has been done.
/// @param data the data transmitted, recorded in lastTransmission
/// @param now the clock time the data was transmitted, recorded in lastTransmissionTime
/// @return always true, at the moment
///
- (BOOL) recordTransmission: (NSString*)data at: (uint64_t)now;

///
/// Called when something has been received.
/// @param data the data received
/// @param now the clock time at the moment the data was received
/// @return true if this data matches the last transmission
/// If the data matches the last transmission and it has not been received previously then a new delay
/// sample is stored in the dataStore and true is returned. This will signal the run manager to start a
/// new measurement cycle.
///
- (BOOL) recordReception: (NSString*)data at: (uint64_t)now;
@end
