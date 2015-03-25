//
//  InputSelectionView.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 25/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "InputSelectionView.h"

@implementation InputSelectionView
@synthesize selectionDelegate;

- (void)awakeFromNib
{
    [super awakeFromNib];
    if (self.bBase) {
        self.bBase.dataSource = self;
        self.bBase.delegate = self;
    }
}

- (void)setBases: (NSArray *)baseNames
{
    assert(self.bBase);
    _baseNames = baseNames;
    [self.bBase reloadAllComponents];
}

- (void)disableBases
{
    if (self.bBase) {
        [self.bBase removeFromSuperview];
        if (self.bBaseLabel) [self.bBaseLabel removeFromSuperview];
        self.bBase = nil;
        self.bBaseLabel = nil;
    }
}

- (NSString *)baseName
{
    if (self.bBase == nil) return nil;
    NSInteger idx = [self.bBase selectedRowInComponent:0];
    return [_baseNames objectAtIndex:idx];
}

- (NSString *)deviceName
{
    NSString *deviceName = self.bInputDeviceName.text;
    return deviceName;
}

// datasource methods
// The number of columns of data
- (int)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (int)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _baseNames.count;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _baseNames[row];
}


@end
