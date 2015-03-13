//
//  DownloadCalibrationTableViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 13/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "DownloadCalibrationTableViewController.h"
#import "MachineDescription.h"
#import "DeviceDescription.h"
#import "CalibrationSharing.h"
#import "VideoInput.h"
#import "AppDelegate.h"

@interface DownloadCalibrationTableViewController ()

@end

@implementation DownloadCalibrationTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _listCalibrations];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (calibrations) return [calibrations count];
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListPrototypeCell" forIndexPath:indexPath];
    NSDictionary *cal = [calibrations objectAtIndex:indexPath.row];
    // Configure the cell...
	NSString *uuid = [cal objectForKey: @"uuid"];
	NSString *calName = [NSString stringWithFormat:@"%@-%@-%@-%@",
						 [cal objectForKey:@"measurementTypeID"],
						 [cal objectForKey:@"machineTypeID"],
						 [cal objectForKey:@"deviceTypeID"],
						 [cal objectForKey:@"uuid"]
						 ];
	cell.textLabel.text = calName;

    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	if ([ad haveCalibration: uuid]) {
		cell.userInteractionEnabled = cell.textLabel.enabled = cell.detailTextLabel.enabled = NO;
	}

    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)_listCalibrations
{
	NSString *machineTypeID = [[MachineDescription thisMachine] machineTypeID];
	NSArray *deviceTypeIDs = [VideoInput allDeviceTypeIDs];
//	deviceTypeIDs = [deviceTypeIDs arrayByAddingObjectsFromArray:[VideoOutputView allDeviceTypeIDs]];
	NSLog(@"Getting calibrations for %@ and %@", machineTypeID, deviceTypeIDs);
	[[CalibrationSharing sharedUploader] listForMachine: machineTypeID andDevices:deviceTypeIDs delegate:self];
	// XXXX Show progress indicator
}

- (void)availableCalibrations: (NSArray *)_calibrations
{
    calibrations = _calibrations;
    [self _updateCalibrations];
}

- (void)_updateCalibrations
{
	[self.tableView reloadData];
}


- (void)didDownload: (MeasurementDataStore *)dataStore
{
	NSLog(@"DidDownload: %@", dataStore);
	if (dataStore) {
		AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		[ad performSelectorOnMainThread:@selector(openUntitledDocumentWithMeasurement:) withObject:dataStore waitUntilDone:NO];
	}
}


- (void)_downloadCalibration: (NSDictionary *)calibration
{
	[[CalibrationSharing sharedUploader] downloadAsynchronously:calibration delegate:self];
}

@end
