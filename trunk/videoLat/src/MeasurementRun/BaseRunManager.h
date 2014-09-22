//
//  BaseRunManager.h
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>
#import "protocols.h"
#import "MeasurementType.h"
#import "RunCollector.h"
#import "RunTypeView.h"
#import "RunStatusView.h"

///
/// Base class for objects that control a delay measurement run, i.e. a sequence of
/// many individual delay measurements and collects and stores the individual delays.
///

@interface BaseRunManager : NSObject <RunOutputManagerProtocol, RunInputManagerProtocol> {
    MeasurementType *measurementType;
    BOOL handlesInput;
    BOOL handlesOutput;
}

+ (void)initialize;
+ (void)registerClass: (Class)managerClass forMeasurementType: (NSString *)name;
+ (Class)classForMeasurementType: (NSString *)name;
+ (void)registerNib: (NSString*)nibName forMeasurementType: (NSString *)name;
+ (NSString *)nibForMeasurementType: (NSString *)name;

@property(readonly) MeasurementType *measurementType;
@property(strong) NSString *outputCode;           // Current code on the display

- (void)terminate;
- (void)stop;
- (void)selectMeasurementType: (NSString *)typeName;
- (void)restart;
- (void)triggerNewOutputValue;

@property bool running;
@property bool preRunning;

@property(weak) IBOutlet RunCollector *collector;
@property(weak) IBOutlet RunStatusView *statusView;
@property(weak) IBOutlet RunTypeView *measurementMaster;
///
/// The inputCompanion and outputCompanion properties need a bit of explanation.
/// If the same RunManager is used for
/// both input and output the following two outlets are NOT assigned in the NIB.
/// The will then be both set to self in awakeFromNib, and this run manager handles both
/// input and output.
/// But for non-symetric measurements (say, hardware light to camera) the NIB instantiates
/// two BaseRunManager subclass instances, and ties them together through the inputCompanion
/// and outputCompanion.
///
@property(weak) IBOutlet BaseRunManager *inputCompanion;

@property(weak) IBOutlet BaseRunManager *outputCompanion;   /// See inputCompanion for a description

@end
