//
//  NewMeasurementTableViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 15/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "NewMeasurementTableViewController.h"
#import "MeasurementType.h"
#import "InputSelectionViewController.h"

@interface NewMeasurementTableViewController ()

@end

@implementation NewMeasurementTableViewController

- (NSArray *)measurementNames
{
	return @[
		@"Video Roundtrip",
		@"Audio Roundtrip",
		@"Video Transmission (Master,Server)",
		@"Video Reception (Slave,Client)"

		];
}

- (void)viewDidLoad {
    [super viewDidLoad];

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
    return [self.measurementNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListPrototypeCell" forIndexPath:indexPath];
 
    // Configure the cell...
    NSString *measurementName = [self.measurementNames objectAtIndex:indexPath.row];
    cell.textLabel.text = measurementName;
    MeasurementType *myType = [MeasurementType forType: measurementName];
    BOOL ok;
    assert(myType);
    MeasurementType *myCalibration = myType.requires;
    if (myCalibration == nil) {
        ok = YES;
    } else {
        ok = [[myCalibration measurementNames] count] > 0;
    }
    cell.userInteractionEnabled = cell.textLabel.enabled = cell.detailTextLabel.enabled = ok;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedMeasurement = [self.measurementNames objectAtIndex: indexPath.row];
	if (selectedMeasurement) {
		[self performSegueWithIdentifier:@"inputSelection" sender:self];
	} else {
		showWarningAlert(@"Selected unknown measurement??");
	}
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	assert([segue.identifier isEqualToString:@"inputSelection"]);
	InputSelectionViewController *mcv = segue.destinationViewController;
	mcv.measurementTypeName = selectedMeasurement;
}

@end
