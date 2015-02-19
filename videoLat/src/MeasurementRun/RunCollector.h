///
///  @file RunCollector.h
///  @brief Defines the RunCollector object.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Cocoa/Cocoa.h>
#import <stdio.h>
#import "Document.h"
#import "protocols.h"
#import "MeasurementDataStore.h"

#undef CLOCK_IN_COLLECTOR
#ifdef CLOCK_IN_COLLECTOR
@interface RunClock : NSObject <ClockProtocol> {
    uint64_t epoch;
}
- (uint64_t) now;
@end
#define BASECLASS RunClock
#else
/// Because CLOCK_IN_COLLECTOR is not defined the RunCollector does not contain a clock.
#define BASECLASS NSObject
#endif

///
/// Helper object for BaseRunManager. Records transmission and reception times and populates
/// MeasurementDataStore.
/// During compile time the decision can be made to either have RunCollector use an internal clock,
/// or use a clock defined externally and assigned in the NIB. The latter is better, and
/// will normally use a clock provided by the input driver.
///
@interface RunCollector : BASECLASS {
    NSString* lastTransmission;         //!< Internal: records most recently transmitted data
    uint64_t lastTransmissionTime;      //!< Internal: records timestamp of most recent transmission
    BOOL lastTransmissionReceived;      //!< Internal: true when lastTramsnission has already been received
	MeasurementDataStore *dataStore;
}
@property(weak) IBOutlet Document *document;    //!< Assigned by NIB: the document this object collects for, used to initialize dataStore
@property(readonly) double average;             //!< accessor for dataStore average
@property(readonly) double stddev;              //!< accessor for dataStore stddev
@property(readonly) int count;                  //!< accessor for dataStore count
@property(readonly) MeasurementDataStore *dataStore;    //!< Where this RunCollector should store the measurements.


///
/// Signals that this RunCollector should start filling its dataStore.
/// @param scenario the measurement type in somewhat-human-readable form
/// @param inputId the input device in somewhat-human-readable form
/// @param inputName the input device in human readable (but possibly ambiguous) form
/// @param outputId the output device in somewhat-human-readable form
/// @param outputName the output device in human readable (but possibly ambiguous) form
///
- (void) startCollecting: (NSString*)scenario input: (NSString*)inputId name: (NSString*)inputName output:(NSString*)outputId name: (NSString*)outputName;
///
/// Signals that this RunCollector should start filling its dataStore, for two-ended measurements.
/// @param scenario the measurement type in somewhat-human-readable form
/// @param _input the input device description received from the remote side
/// @param outputId the output device in somewhat-human-readable form
/// @param outputName the output device in human readable (but possibly ambiguous) form
///
- (void) startCollecting: (NSString*)scenario input: (DeviceDescription *)_input output:(NSString*)outputId name: (NSString*)outputName;
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
